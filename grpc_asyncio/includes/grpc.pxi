# Copyright 2017 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# distutils: language=c++

from libc.stdint cimport uint32_t, uint8_t

ctypedef long int64_t
ctypedef int int32_t

cdef extern from "grpc/support/alloc.h":

  void *gpr_malloc(size_t size) nogil
  void *gpr_zalloc(size_t size) nogil
  void gpr_free(void *ptr) nogil
  void *gpr_realloc(void *p, size_t size) nogil

cdef extern from "grpc/byte_buffer_reader.h":

  struct grpc_byte_buffer_reader:
    pass

cdef extern from "grpc/grpc.h":
    const int GRPC_INITIAL_METADATA_USED_MASK

    ctypedef enum grpc_arg_type:
        GRPC_ARG_STRING
        GRPC_ARG_INTEGER
        GRPC_ARG_POINTER

    ctypedef struct grpc_arg_pointer_vtable:
        void *(*copy)(void *)
        void (*destroy)(void *)
        int (*cmp)(void *, void *)

    ctypedef struct grpc_arg_value_pointer:
        void *address "p"
        grpc_arg_pointer_vtable *vtable

    union grpc_arg_value:
        char *string
        int integer
        grpc_arg_value_pointer pointer

    ctypedef struct grpc_arg:
        grpc_arg_type type
        char *key
        grpc_arg_value value

    ctypedef struct grpc_channel_args:
        size_t arguments_length "num_args"
        grpc_arg *arguments "args"

    ctypedef enum grpc_connectivity_state:
        GRPC_CHANNEL_IDLE
        GRPC_CHANNEL_CONNECTING
        GRPC_CHANNEL_READY
        GRPC_CHANNEL_TRANSIENT_FAILURE
        GRPC_CHANNEL_SHUTDOWN

    ctypedef enum gpr_clock_type:
        GPR_CLOCK_MONOTONIC
        GPR_CLOCK_REALTIME
        GPR_CLOCK_PRECISE
        GPR_TIMESPAN

    ctypedef struct gpr_timespec:
        int64_t seconds "tv_sec"
        int32_t nanoseconds "tv_nsec"
        gpr_clock_type clock_type

    ctypedef struct grpc_channel:
        pass

    ctypedef struct grpc_completion_queue:
        pass

    ctypedef struct grpc_call:
        pass

    ctypedef struct grpc_slice:
        pass

    ctypedef struct grpc_metadata:
        grpc_slice key
        grpc_slice value

    ctypedef enum grpc_op_type:
        GRPC_OP_SEND_INITIAL_METADATA
        GRPC_OP_SEND_MESSAGE
        GRPC_OP_SEND_CLOSE_FROM_CLIENT
        GRPC_OP_SEND_STATUS_FROM_SERVER
        GRPC_OP_RECV_INITIAL_METADATA
        GRPC_OP_RECV_MESSAGE
        GRPC_OP_RECV_STATUS_ON_CLIENT
        GRPC_OP_RECV_CLOSE_ON_SERVER

    ctypedef enum grpc_status_code:
        GRPC_STATUS_OK
        GRPC_STATUS_CANCELLED
        GRPC_STATUS_UNKNOWN
        GRPC_STATUS_INVALID_ARGUMENT
        GRPC_STATUS_DEADLINE_EXCEEDED
        GRPC_STATUS_NOT_FOUND
        GRPC_STATUS_ALREADY_EXISTS
        GRPC_STATUS_PERMISSION_DENIED
        GRPC_STATUS_UNAUTHENTICATED
        GRPC_STATUS_RESOURCE_EXHAUSTED
        GRPC_STATUS_FAILED_PRECONDITION
        GRPC_STATUS_ABORTED
        GRPC_STATUS_OUT_OF_RANGE
        GRPC_STATUS_UNIMPLEMENTED
        GRPC_STATUS_INTERNAL
        GRPC_STATUS_UNAVAILABLE
        GRPC_STATUS_DATA_LOSS
        GRPC_STATUS__DO_NOT_USE

    ctypedef enum grpc_call_error:
        GRPC_CALL_OK
        GRPC_CALL_ERROR
        GRPC_CALL_ERROR_NOT_ON_SERVER
        GRPC_CALL_ERROR_NOT_ON_CLIENT
        GRPC_CALL_ERROR_ALREADY_ACCEPTED
        GRPC_CALL_ERROR_ALREADY_INVOKED
        GRPC_CALL_ERROR_NOT_INVOKED
        GRPC_CALL_ERROR_ALREADY_FINISHED
        GRPC_CALL_ERROR_TOO_MANY_OPERATIONS
        GRPC_CALL_ERROR_INVALID_FLAGS
        GRPC_CALL_ERROR_INVALID_METADATA

    ctypedef struct grpc_metadata_array:
        size_t count
        size_t capacity
        grpc_metadata *metadata

    ctypedef struct grpc_op_send_initial_metadata_maybe_compression_level:
        uint8_t is_set
        grpc_compression_level level

    ctypedef struct grpc_op_data_send_initial_metadata:
        size_t count
        grpc_metadata *metadata
        grpc_op_send_initial_metadata_maybe_compression_level maybe_compression_level

    ctypedef struct grpc_op_data_send_status_from_server:
        size_t trailing_metadata_count
        grpc_metadata *trailing_metadata
        grpc_status_code status
        grpc_slice *status_details

    ctypedef struct grpc_op_data_recv_status_on_client:
        grpc_metadata_array *trailing_metadata
        grpc_status_code *status
        grpc_slice *status_details
        char** error_string

    ctypedef struct grpc_op_data_recv_close_on_server:
        int *cancelled

    ctypedef struct grpc_op_data_send_message:
        grpc_byte_buffer *send_message

    ctypedef struct grpc_byte_buffer:
        pass

    ctypedef struct grpc_op_data_receive_message:
        grpc_byte_buffer **receive_message "recv_message"

    ctypedef struct grpc_op_data_receive_initial_metadata:
        grpc_metadata_array *receive_initial_metadata "recv_initial_metadata"

    union grpc_op_data:
        grpc_op_data_send_initial_metadata send_initial_metadata
        grpc_op_data_send_message send_message
        grpc_op_data_send_status_from_server send_status_from_server
        grpc_op_data_receive_initial_metadata receive_initial_metadata "recv_initial_metadata"
        grpc_op_data_receive_message receive_message "recv_message"
        grpc_op_data_recv_status_on_client receive_status_on_client "recv_status_on_client"
        grpc_op_data_recv_close_on_server receive_close_on_server "recv_close_on_server"

    ctypedef struct grpc_op:
        grpc_op_type type "op"
        uint32_t flags
        void * reserved
        grpc_op_data data

    void grpc_metadata_array_init(grpc_metadata_array *array) nogil

    void grpc_metadata_array_destroy(grpc_metadata_array *array) nogil

    grpc_byte_buffer *grpc_raw_byte_buffer_create(
        grpc_slice *slices,
        size_t nslices) nogil

    size_t grpc_byte_buffer_length(grpc_byte_buffer *bb) nogil

    void grpc_byte_buffer_destroy(grpc_byte_buffer *byte_buffer) nogil

    # Declare functions for function-like macros (because Cython)...
    void *grpc_slice_start_ptr "GRPC_SLICE_START_PTR" (grpc_slice s) nogil
    size_t grpc_slice_length "GRPC_SLICE_LENGTH" (grpc_slice s) nogil

    void grpc_slice_unref(grpc_slice s) nogil

    grpc_slice grpc_slice_from_copied_buffer(
        const char *source,
        size_t len) nogil

    gpr_timespec gpr_inf_future(gpr_clock_type type) nogil

    gpr_timespec gpr_convert_clock_type(
        gpr_timespec t,
        gpr_clock_type target_clock) nogil

    void grpc_init() nogil

    void grpc_shutdown() nogil

    grpc_completion_queue *grpc_completion_queue_create_for_callback(
        grpc_experimental_completion_queue_functor* shutdown_callback,
        void *reserved) nogil

    grpc_completion_queue *grpc_completion_queue_create_for_next(
        void *reserved) nogil

    grpc_channel *grpc_insecure_channel_create(
        const char *target,
        const grpc_channel_args *args,
        void *reserved) nogil

    grpc_connectivity_state grpc_channel_check_connectivity_state(
        grpc_channel *channel,
        int try_to_connect) nogil

    void grpc_channel_watch_connectivity_state(
        grpc_channel *channel,
        grpc_connectivity_state last_observed_state,
        gpr_timespec deadline,
        grpc_completion_queue *cq,
        void *tag) nogil

    grpc_call *grpc_channel_create_call(
        grpc_channel *channel,
        grpc_call *parent_call,
        uint32_t propagation_mask,
        grpc_completion_queue *completion_queue,
        grpc_slice method,
        const grpc_slice *host,
        gpr_timespec deadline,
        void *reserved) nogil

    grpc_call_error grpc_call_start_batch(
        grpc_call *call,
        const grpc_op *ops,
        size_t nops,
        void *tag,
        void *reserved) nogil

    void grpc_call_unref(grpc_call *call) nogil

    int grpc_byte_buffer_reader_init(
        grpc_byte_buffer_reader *reader,
        grpc_byte_buffer *buffer) nogil

    int grpc_byte_buffer_reader_next(
        grpc_byte_buffer_reader *reader,
        grpc_slice *slice) nogil

    void grpc_byte_buffer_reader_destroy(
        grpc_byte_buffer_reader *reader) nogil

cdef extern from "grpc/impl/codegen/slice.h":
    struct grpc_slice_buffer:
        int count

cdef extern from "grpc/impl/codegen/grpc_types.h":
    ctypedef struct grpc_experimental_completion_queue_functor:
        void (*functor_run)(grpc_experimental_completion_queue_functor*, int);

cdef extern from "src/core/lib/iomgr/error.h":
    struct grpc_error:
        pass

cdef extern from "src/core/lib/iomgr/gevent_util.h":
    grpc_error* grpc_socket_error(char* error) 
    char* grpc_slice_buffer_start(grpc_slice_buffer* buffer, int i)
    int grpc_slice_buffer_length(grpc_slice_buffer* buffer, int i)

cdef extern from "src/core/lib/iomgr/sockaddr.h":
    ctypedef struct grpc_sockaddr:
        pass

cdef extern from "src/core/lib/iomgr/resolve_address.h":
    ctypedef struct grpc_resolved_addresses:
        size_t naddrs
        grpc_resolved_address* addrs

    ctypedef struct grpc_resolved_address:
        char[128] addr
        size_t len

cdef extern from "src/core/lib/iomgr/resolve_address_custom.h":
    struct grpc_custom_resolver:
        pass

    struct grpc_custom_resolver_vtable:
        grpc_error* (*resolve)(char* host, char* port, grpc_resolved_addresses** res);
        void (*resolve_async)(grpc_custom_resolver* resolver, char* host, char* port);

    void grpc_custom_resolve_callback(grpc_custom_resolver* resolver,
                                      grpc_resolved_addresses* result,
                                      grpc_error* error);

cdef extern from "src/core/lib/iomgr/tcp_custom.h":
    struct grpc_custom_socket:
        void* impl
        # We don't care about the rest of the fields

    ctypedef void (*grpc_custom_connect_callback)(grpc_custom_socket* socket,
                                                  grpc_error* error)
    ctypedef void (*grpc_custom_write_callback)(grpc_custom_socket* socket,
                                                grpc_error* error)
    ctypedef void (*grpc_custom_read_callback)(grpc_custom_socket* socket,
                                               size_t nread, grpc_error* error)
    ctypedef void (*grpc_custom_accept_callback)(grpc_custom_socket* socket,
                                                 grpc_custom_socket* client,
                                                 grpc_error* error)
    ctypedef void (*grpc_custom_close_callback)(grpc_custom_socket* socket)

    struct grpc_socket_vtable:
        grpc_error* (*init)(grpc_custom_socket* socket, int domain);
        void (*connect)(grpc_custom_socket* socket, const grpc_sockaddr* addr,
                      size_t len, grpc_custom_connect_callback cb);
        void (*destroy)(grpc_custom_socket* socket);
        void (*shutdown)(grpc_custom_socket* socket);
        void (*close)(grpc_custom_socket* socket, grpc_custom_close_callback cb);
        void (*write)(grpc_custom_socket* socket, grpc_slice_buffer* slices,
                      grpc_custom_write_callback cb);
        void (*read)(grpc_custom_socket* socket, char* buffer, size_t length,
                     grpc_custom_read_callback cb);
        grpc_error* (*getpeername)(grpc_custom_socket* socket,
                                   const grpc_sockaddr* addr, int* len);
        grpc_error* (*getsockname)(grpc_custom_socket* socket,
                                   const grpc_sockaddr* addr, int* len);
        grpc_error* (*bind)(grpc_custom_socket* socket, const grpc_sockaddr* addr,
                            size_t len, int flags);
        grpc_error* (*listen)(grpc_custom_socket* socket);
        void (*accept)(grpc_custom_socket* socket, grpc_custom_socket* client,
                       grpc_custom_accept_callback cb);

cdef extern from "grpc/compression.h":
    ctypedef enum grpc_compression_algorithm:
        GRPC_COMPRESS_NONE
        GRPC_COMPRESS_DEFLATE
        GRPC_COMPRESS_GZIP
        GRPC_COMPRESS_STREAM_GZIP
        GRPC_COMPRESS_ALGORITHMS_COUNT

    ctypedef enum grpc_compression_level:
        GRPC_COMPRESS_LEVEL_NONE
        GRPC_COMPRESS_LEVEL_LOW
        GRPC_COMPRESS_LEVEL_MED
        GRPC_COMPRESS_LEVEL_HIGH
        GRPC_COMPRESS_LEVEL_COUNT

cdef extern from "src/core/lib/iomgr/timer_custom.h":
    struct grpc_custom_timer:
        void* timer
        int timeout_ms

    struct grpc_custom_timer_vtable:
        void (*start)(grpc_custom_timer* t);
        void (*stop)(grpc_custom_timer* t);

    void grpc_custom_timer_callback(grpc_custom_timer* t, grpc_error* error);

cdef extern from "src/core/lib/iomgr/pollset_custom.h":
    struct grpc_custom_poller_vtable:
        void (*init)()
        void (*poll)(size_t timeout_ms)
        void (*kick)()
        void (*shutdown)()

cdef extern from "src/core/lib/iomgr/iomgr_custom.h":
    void grpc_custom_iomgr_init(grpc_socket_vtable* socket,
                                grpc_custom_resolver_vtable* resolver,
                                grpc_custom_timer_vtable* timer,
                                grpc_custom_poller_vtable* poller);

cdef extern from "src/core/lib/iomgr/sockaddr_utils.h":
    int grpc_sockaddr_get_port(const grpc_resolved_address *addr);
    int grpc_sockaddr_to_string(char **out, const grpc_resolved_address *addr,
                                int normalize);
    void grpc_string_to_sockaddr(grpc_resolved_address *out, char* addr, int port);
    int grpc_sockaddr_set_port(const grpc_resolved_address *resolved_addr,
                               int port)
    const char* grpc_sockaddr_get_uri_scheme(const grpc_resolved_address* resolved_addr)
