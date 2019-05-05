from libc.stdlib cimport malloc

cdef grpc_resolved_addresses* tuples_to_resolvaddr(tups):
    cdef grpc_resolved_addresses* addresses
    tups_set = set((tup[4][0], tup[4][1]) for tup in tups)
    addresses = <grpc_resolved_addresses*> malloc(sizeof(grpc_resolved_addresses))
    addresses.naddrs = len(tups_set)
    addresses.addrs = <grpc_resolved_address*> malloc(sizeof(grpc_resolved_address) * len(tups_set))
    i = 0
    for tup in set(tups_set):
        grpc_string_to_sockaddr(&addresses.addrs[i], tup[0].encode(), tup[1])
        i += 1
    return addresses


cdef class Resolver:
    def __cinit__(self):
        self.g_resolver = NULL
        self.host = NULL
        self.port = NULL
        self.task_resolve = None

    @staticmethod
    cdef Resolver create(grpc_custom_resolver* g_resolver):
        resolver = Resolver()
        resolver.g_resolver = g_resolver
        return resolver

    def __repr__(self):
        class_name = self.__class__.__name__ 
        id_ = id(self)
        return f"<{class_name} {id_}>"

    def _resolve_cb(self, future):
        error = False
        try:
            res = future.result()
        except Exception as e:
            error = True
        finally:
            self.task_resolve = None

        if not error:
            grpc_custom_resolve_callback(
                <grpc_custom_resolver*>self.g_resolver,
                tuples_to_resolvaddr(res),
                <grpc_error*>0
            )
        else:
            grpc_custom_resolve_callback(
                <grpc_custom_resolver*>self.g_resolver,
                NULL,
                grpc_socket_error("getaddrinfo {}".format(str(e)).encode())
            )

    cdef void resolve(self, char* host, char* port):
        assert not self.task_resolve

        loop = asyncio.get_running_loop()
        self.task_resolve = asyncio.create_task(
            loop.getaddrinfo(host, port)
        )
        self.task_resolve.add_done_callback(self._resolve_cb)
