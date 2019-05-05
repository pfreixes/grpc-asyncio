import asyncio

cdef class Timer:
    def __cinit__(self):
        self.g_timer = NULL
        self.timer_handler = None
        self.active = 0

    @staticmethod
    cdef Timer create(grpc_custom_timer * g_timer, deadline):
        timer = Timer()
        timer.g_timer = g_timer
        timer.deadline = deadline
        timer.timer_handler = asyncio.get_running_loop().call_later(deadline, timer._on_deadline)
        timer.active = 1
        return timer

    def _on_deadline(self):
        self.active = 0
        grpc_custom_timer_callback(self.g_timer, <grpc_error*>0)

    def __repr__(self):
        class_name = self.__class__.__name__ 
        id_ = id(self)
        return f"<{class_name} {id_} deadline={self.deadline} active={self.active}>"

    cdef stop(self):
        if self.active == 0:
            return

        self.timer_handler.cancel()
        self.active = 0
