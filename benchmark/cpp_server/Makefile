_default: cpp_server

CXX = g++
CXXFLAGS += -I../../vendor/grpc/include
CXXFLAGS += -std=c++11
LDFLAGS += -L../../vendor/grpc/libs/opt\
		   -lgrpc\
           -lgrpc++\
		   -lprotobuf\
           -ldl

clean:
	rm *.o cpp_server

cpp_server: echo.pb.o echo.grpc.pb.o cpp_server.o
	$(CXX) $^ $(LDFLAGS) -o $@

protos:
	protoc -I ../../proto/ --cpp_out=. ../../proto/echo.proto
	protoc -I ../../proto/ --grpc_out=. --plugin=protoc-gen-grpc=../../vendor/grpc/bins/opt/grpc_cpp_plugin ../../proto/echo.proto


.PHONY: protos cpp_server
