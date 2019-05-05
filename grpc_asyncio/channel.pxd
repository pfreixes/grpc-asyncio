cimport cpython

cdef struct CallbackGlue:
    grpc_experimental_completion_queue_functor functor
    cpython.PyObject *obj


cdef class Channel:
    cdef:
        CallbackGlue watcher_connector
        CallbackGlue watcher_call
        grpc_completion_queue * cq
        grpc_experimental_completion_queue_functor functor
        grpc_channel * g_channel
        bytes target
        object _waiter_connection
        object _waiter_call

    @staticmethod
    cdef void functor_run(grpc_experimental_completion_queue_functor* functor, int succeed)
    @staticmethod
    cdef void watcher_connector_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed)
    @staticmethod
    cdef void watcher_call_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed)
