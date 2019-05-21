import socket

from libc cimport string

cdef class Socket:
    def __cinit__(self):
        self.g_socket = NULL
        self.g_connect_cb = NULL
        self.reader = None
        self.writer = None
        self.task_connect = None
        self.task_read = None
        self.read_buffer = NULL

    @staticmethod
    cdef Socket create(grpc_custom_socket * g_socket):
        socket = Socket()
        socket.g_socket = g_socket
        return socket

    def __repr__(self):
        class_name = self.__class__.__name__ 
        id_ = id(self)
        connected = self.is_connected()
        return f"<{class_name} {id_} connected={connected}>"

    def _connect_cb(self, future):
        error = False
        try:
            self.reader, self.writer = future.result()
        except Exception as e:
            error = True
        finally:
            self.task_connect = None

        if not error:
            # gRPC default posix implementation disables nagle
            # algorithm.
            sock = self.writer.transport.get_extra_info('socket')
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)

            self.g_connect_cb(
                <grpc_custom_socket*>self.g_socket,
                <grpc_error*>0
            )
        else:
            self.g_connect_cb(
                <grpc_custom_socket*>self.g_socket,
                grpc_socket_error("connect {}".format(str(e)).encode())
            )

    def _read_cb(self, future):
        error = False
        try:
            buffer_ = future.result()
        except Exception as e:
            error = True
            error_msg = str(e)
        finally:
            self.task_read = None

        if not error:
            string.memcpy(
                <void*>self.read_buffer,
                <char*>buffer_,
                len(buffer_)
            )
            self.g_read_cb(
                <grpc_custom_socket*>self.g_socket,
                len(buffer_),
                <grpc_error*>0
            )
        else:
            self.g_read_cb(
                <grpc_custom_socket*>self.g_socket,
                -1,
                grpc_socket_error("read {}".format(error_msg).encode())
            )

    cdef void connect(self, object host, object port, grpc_custom_connect_callback g_connect_cb):
        assert not self.task_connect

        self.task_connect = asyncio.create_task(
            asyncio.open_connection(host, port)
        )
        self.task_connect.add_done_callback(self._connect_cb)
        self.g_connect_cb = g_connect_cb

    cdef void read(self, char * buffer_, size_t length, grpc_custom_read_callback g_read_cb):
        assert not self.task_read

        self.task_read = asyncio.create_task(
            self.reader.read(n=length)
        )
        self.task_read.add_done_callback(self._read_cb)
        self.g_read_cb = g_read_cb
        self.read_buffer = buffer_
 
    cdef void write(self, grpc_slice_buffer * g_slice_buffer, grpc_custom_write_callback g_write_cb):
        buffer_ = bytearray()
        for i in range(g_slice_buffer.count):
            start = grpc_slice_buffer_start(g_slice_buffer, i)
            length = grpc_slice_buffer_length(g_slice_buffer, i)
            buffer_.extend(<bytes>start[:length])

        self.writer.write(buffer_)

        g_write_cb(
            <grpc_custom_socket*>self.g_socket,
            <grpc_error*>0
        )


    cdef bint is_connected(self):
        return self.reader and not self.reader._transport.is_closing()
