cdef class Resolver:
    cdef:
        grpc_custom_resolver* g_resolver
        object task_resolve
        char* host
        char* port

    @staticmethod
    cdef Resolver create(grpc_custom_resolver* g_resolver)

    cdef void resolve(self, char* host, char* port)
