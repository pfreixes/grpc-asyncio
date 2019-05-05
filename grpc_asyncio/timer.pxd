cdef class Timer:
    cdef:
        grpc_custom_timer * g_timer
        object deadline
        object timer_handler
        int active

    @staticmethod
    cdef Timer create(grpc_custom_timer * g_timer, deadline)

    cdef stop(self)
