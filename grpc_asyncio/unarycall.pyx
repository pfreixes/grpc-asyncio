cimport cpython

import time


cdef class _UnaryCall:

    def __cinit__(self, Channel channel):
        self.channel = channel
        self.functor.functor_run = _UnaryCall.functor_run

        self.cq = grpc_completion_queue_create_for_callback(
            <grpc_experimental_completion_queue_functor *> &self.functor,
            NULL
        )

        self.watcher_call.functor.functor_run = _UnaryCall.watcher_call_functor_run
        self.watcher_call.obj = <cpython.PyObject *> self
        self._waiter_call = None

    def __repr__(self):
        class_name = self.__class__.__name__ 
        id_ = id(self)
        return f"<{class_name} {id_}>"

    @staticmethod
    cdef void functor_run(grpc_experimental_completion_queue_functor* functor, int succeed):
        pass
 
    @staticmethod
    cdef void watcher_call_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed):
        call = <_UnaryCall>(<CallbackGlue *>functor).obj

        assert call._waiter_call

        if succeed == 0:
            call._waiter_call.set_exception(Exception("Some error ocurred"))
        else:
            call._waiter_call.set_result(None)

    async def process(self, method, request):
        cdef grpc_call * call
        cdef grpc_slice method_slice
        cdef grpc_op * ops
        cdef grpc_slice message_slice
        cdef grpc_byte_buffer * message_byte_buffer
        cdef grpc_metadata_array recv_initial_metadata
        cdef grpc_byte_buffer * recv_message_byte_buffer
        cdef grpc_byte_buffer_reader recv_message_reader
        cdef bint recv_message_reader_status
        cdef grpc_slice recv_message_slice
        cdef size_t recv_message_slice_length
        cdef void *recv_message_slice_pointer
        cdef grpc_metadata_array recv_trailing_metadata
        cdef grpc_status_code recv_status_code
        cdef grpc_slice recv_status_details
        cdef const char* recv_error_string
        cdef grpc_call_error call_status

        recv_message_byte_buffer = NULL

        method_slice = grpc_slice_from_copied_buffer(
            <const char *> method,
            <size_t> len(method) 
        )

        call = grpc_channel_create_call(
            self.channel.g_channel,
            NULL,
            0,
            self.cq,
            method_slice,
            NULL,
            _timespec_from_time(int(time.time()) + 4),
            NULL
        )

        grpc_slice_unref(method_slice)

        ops = <grpc_op *>gpr_malloc(sizeof(grpc_op) * 6)

        ops[0].type = GRPC_OP_SEND_INITIAL_METADATA
        ops[0].flags &= GRPC_INITIAL_METADATA_USED_MASK
        ops[0].reserved = NULL
        ops[0].data.send_initial_metadata.count = 0
        ops[0].data.send_initial_metadata.metadata = NULL
        ops[0].data.send_initial_metadata.maybe_compression_level.is_set
    
        ops[1].type = GRPC_OP_SEND_MESSAGE
        ops[1].flags = 0
        ops[1].reserved = NULL
        message_slice = grpc_slice_from_copied_buffer(request, len(request))
        send_message_byte_buffer = grpc_raw_byte_buffer_create(&message_slice, 1)
        ops[1].data.send_message.send_message = send_message_byte_buffer
        grpc_slice_unref(message_slice)

        ops[2].type = GRPC_OP_SEND_CLOSE_FROM_CLIENT
        ops[2].flags = 0
        ops[2].reserved = NULL
 
        ops[3].type = GRPC_OP_RECV_INITIAL_METADATA
        ops[3].flags = 0
        ops[3].reserved = NULL
        grpc_metadata_array_init(&recv_initial_metadata)
        ops[3].data.receive_initial_metadata.receive_initial_metadata = &recv_initial_metadata

        ops[4].type = GRPC_OP_RECV_MESSAGE
        ops[4].flags = 0
        ops[4].reserved = NULL
        ops[4].data.receive_message.receive_message = &recv_message_byte_buffer

        ops[5].type = GRPC_OP_RECV_STATUS_ON_CLIENT
        ops[5].flags = 0
        ops[5].reserved = NULL
        grpc_metadata_array_init(&recv_trailing_metadata)
        ops[5].data.receive_status_on_client.trailing_metadata = &recv_trailing_metadata
        ops[5].data.receive_status_on_client.status = &recv_status_code
        ops[5].data.receive_status_on_client.status_details = &recv_status_details
        ops[5].data.receive_status_on_client.error_string = &recv_error_string

        self._waiter_call = asyncio.get_running_loop().create_future()

        call_status = grpc_call_start_batch(
            call,
            ops,
            6,
            &self.watcher_call.functor,
            NULL
        )

        if call_status != GRPC_CALL_OK:
            self._waiter_call = None
            raise Exception("Error with grpc_call_start_batch {}".format(call_status))

        await self._waiter_call

        if recv_message_byte_buffer != NULL:
            recv_message_reader_status = grpc_byte_buffer_reader_init(
                &recv_message_reader,
                recv_message_byte_buffer
            )
            if recv_message_reader_status:
                message = bytearray()
                while grpc_byte_buffer_reader_next(&recv_message_reader, &recv_message_slice):
                    recv_message_slice_pointer = grpc_slice_start_ptr(recv_message_slice)
                    recv_message_slice_length = grpc_slice_length(recv_message_slice)
                    message += (<char *>recv_message_slice_pointer)[:recv_message_slice_length]
                    grpc_slice_unref(recv_message_slice)
                grpc_byte_buffer_reader_destroy(&recv_message_reader)
                return bytes(message)
            else:
                return None
        else:
            return None
