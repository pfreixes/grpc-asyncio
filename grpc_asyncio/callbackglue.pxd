cimport cpython

cdef struct CallbackGlue:
    grpc_experimental_completion_queue_functor functor
    cpython.PyObject *obj
