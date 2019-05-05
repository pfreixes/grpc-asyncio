cdef class Socket:
    cdef:
        grpc_custom_socket * g_socket
        grpc_custom_connect_callback g_connect_cb
        grpc_custom_read_callback g_read_cb
        object reader
        object writer
        object task_read
        object task_connect
        char * read_buffer

    @staticmethod
    cdef Socket create(grpc_custom_socket * g_socket)

    cdef void connect(self, object host, object port, grpc_custom_connect_callback g_connect_cb)
    cdef void write(self, grpc_slice_buffer * g_slice_buffer, grpc_custom_write_callback g_write_cb)
    cdef void read(self, char * buffer_, size_t length, grpc_custom_read_callback g_read_cb)
    cdef bint is_connected(self)
