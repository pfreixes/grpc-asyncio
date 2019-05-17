import grpc

from time import sleep
from concurrent import futures

from proto import echo_pb2
from proto import echo_pb2_grpc


class EchoServer(echo_pb2_grpc.EchoServicer):
    def Hi(self, request, context):
        return echo_pb2.EchoReply(message=request.message)


if __name__ == "__main__":
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=1))
    echo_pb2_grpc.add_EchoServicer_to_server(EchoServer(), server)
    server.add_insecure_port('127.0.0.1:3333')
    server.start()
    while True:
        sleep(1)

