import asyncio
from cpython cimport Py_INCREF, Py_DECREF

from libc cimport string
include "timespec.pyx"
include "socket.pyx"
include "channel.pyx"
include "timer.pyx"
include "resolver.pyx"


cdef grpc_socket_vtable socket_vtable
cdef grpc_custom_resolver_vtable resolver_vtable
cdef grpc_custom_timer_vtable timer_vtable
cdef grpc_custom_poller_vtable pollset_vtable


cdef str _decode(bytes bytestring):
    if isinstance(bytestring, (str,)):
        return <str>bytestring
    else:
        try:
            return bytestring.decode('utf8')
        except UnicodeDecodeError:
            print('Invalid encoding on %s', bytestring)
            return bytestring.decode('latin1')


cdef resolved_addr_to_tuple(grpc_resolved_address* address):
    cdef char* res_str
    port = grpc_sockaddr_get_port(address)
    str_len = grpc_sockaddr_to_string(&res_str, address, 0)
    byte_str = _decode(<bytes>res_str[:str_len])
    if byte_str.endswith(':' + str(port)):
        byte_str = byte_str[:(0 - len(str(port)) - 1)]
    byte_str = byte_str.lstrip('[')
    byte_str = byte_str.rstrip(']')
    byte_str = '{}'.format(byte_str)
    return byte_str, port


cdef sockaddr_to_tuple(const grpc_sockaddr* address, size_t length):
  cdef grpc_resolved_address c_addr
  string.memcpy(<void*>c_addr.addr, <void*> address, length)
  c_addr.len = length
  return resolved_addr_to_tuple(&c_addr)


cdef grpc_error* socket_init(
        grpc_custom_socket* g_socket,
        int domain) with gil:
    socket = Socket.create(g_socket)
    Py_INCREF(socket)
    g_socket.impl = <void*>socket
    return <grpc_error*>0


cdef void socket_destroy(grpc_custom_socket* g_socket) with gil:
    Py_DECREF(<Socket>g_socket.impl)


cdef void socket_connect(
        grpc_custom_socket* g_socket,
        const grpc_sockaddr* g_addr,
        size_t addr_len,
        grpc_custom_connect_callback g_connect_cb) with gil:

    host, port = sockaddr_to_tuple(g_addr, addr_len)
    socket = <Socket>g_socket.impl
    socket.connect(host, port, g_connect_cb)


cdef void socket_close(
        grpc_custom_socket* g_socket,
        grpc_custom_close_callback g_close_cb) with gil:
    socket = (<Socket>g_socket.impl)
    if socket.is_connected():
        socket.writer.close()
    g_close_cb(g_socket)


cdef void socket_shutdown(grpc_custom_socket* g_socket) with gil:
    raise NotImplemented()


cdef void socket_write(
        grpc_custom_socket* g_socket,
        grpc_slice_buffer* g_slice_buffer,
        grpc_custom_write_callback g_write_cb) with gil:
    socket = (<Socket>g_socket.impl)
    socket.write(g_slice_buffer, g_write_cb)


cdef void socket_read(
        grpc_custom_socket* g_socket,
        char* buffer_,
        size_t length,
        grpc_custom_read_callback g_read_cb) with gil:
    socket = (<Socket>g_socket.impl)
    socket.read(buffer_, length, g_read_cb)


cdef grpc_error* socket_getpeername(
        grpc_custom_socket* g_socket,
        const grpc_sockaddr* g_addr,
        int* length) with gil:
    raise NotImplemented()


cdef grpc_error* socket_getsockname(
        grpc_custom_socket* g_socket,
        const grpc_sockaddr* g_addr,
        int* length) with gil:
    raise NotImplemented()


cdef grpc_error* socket_listen(grpc_custom_socket* g_socket) with gil:
    raise NotImplemented()


cdef grpc_error* socket_bind(
        grpc_custom_socket* g_socket,
        const grpc_sockaddr* g_addr,
        size_t len, int flags) with gil:
    raise NotImplemented()


cdef void socket_accept(
        grpc_custom_socket* g_socket,
        grpc_custom_socket* g_socket_client,
        grpc_custom_accept_callback g_accept_cb) with gil:
    raise NotImplemented()


cdef grpc_error* resolve(
        char* host,
        char* port,
        grpc_resolved_addresses** res) with gil:
    raise NotImplemented()


cdef void resolve_async(
        grpc_custom_resolver* g_resolver,
        char* host,
        char* port) with gil:
    resolver = Resolver.create(g_resolver)
    resolver.resolve(host, port)


cdef void timer_start(grpc_custom_timer* t) with gil:
    timer = Timer.create(t, t.timeout_ms / 1000.0)
    Py_INCREF(timer)
    t.timer = <void*>timer


cdef void timer_stop(grpc_custom_timer* t) with gil:
    timer = <Timer>t.timer
    timer.stop()
    Py_DECREF(timer)


cdef void init_loop() with gil:
    pass


cdef void destroy_loop() with gil:
    pass


cdef void kick_loop() with gil:
    pass


cdef void run_loop(size_t timeout_ms) with gil:
    pass


def grpc_init_asyncio():

    resolver_vtable.resolve = resolve
    resolver_vtable.resolve_async = resolve_async

    socket_vtable.init = socket_init
    socket_vtable.connect = socket_connect
    socket_vtable.destroy = socket_destroy
    socket_vtable.shutdown = socket_shutdown
    socket_vtable.close = socket_close
    socket_vtable.write = socket_write
    socket_vtable.read = socket_read
    socket_vtable.getpeername = socket_getpeername
    socket_vtable.getsockname = socket_getsockname
    socket_vtable.bind = socket_bind
    socket_vtable.listen = socket_listen
    socket_vtable.accept = socket_accept

    timer_vtable.start = timer_start
    timer_vtable.stop = timer_stop

    pollset_vtable.init = init_loop
    pollset_vtable.poll = run_loop
    pollset_vtable.kick = kick_loop
    pollset_vtable.shutdown = destroy_loop

    grpc_custom_iomgr_init(
        &socket_vtable,
        &resolver_vtable,
        &timer_vtable,
        &pollset_vtable
    )
    grpc_init()
