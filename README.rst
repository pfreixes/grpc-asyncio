**DISCLAIMER**: Just a Proof of Concept.

Native `Asyncio <https://docs.python.org/3/library/asyncio.html>`_ implementation for `gRPC <https://grpc.io/>`_.

This Proof fo Concept implements a simple *unary* call, implementing a naive asynchronous client which is tested by connecting
to an external server that uses the official synchronous implementation for Python.

The following snippet shows how the client is initalized and how the *unary* call is executed:

.. code-block:: python

    grpc_init_asyncio()
    channel = await create_channel("127.0.0.1", 3333)
    response = await channel.unary_call(
        b'/echo.Echo/Hi',
        echo_pb2.EchoRequest(message="Hi Grpc Asyncio").SerializeToString()
    )


Development of grpc-asyncio
---------------------------

To build grpc-asyncio you'll need to clone the repository and build the gRPC package shipped as 
a git submodule, read which dependencies are needed to build the gRPC package in your OS in this
file `guide <https://github.com/grpc/grpc/blob/master/BUILDING.md>`_ and follow the next commands::

    $ git clone --recursive git@github.com:pfreixes/grpc-asyncio.git
    $ cd grpc-asyncio/vendor/grpc
    $ make

For debugging purposes the library can be compiled in debug mode, as can be seen in the following command::
    
    $ CONFIG=dbg make

The debug mode will allow you to get an extra set of messages when the gRPC library is executed with the traces enabled, also
debugers will leverage on that by using the extra information emitted by the compiler.

To build the grpc-asyncio package we will go back to the root directory of the `grpc-asyncio` package
and we will follow the next commands::

    $ make install-dev
    $ make compile

For running the test we will run the following command::

    $ make test

The environment variable `DEBUG=True` can be used to run the test which tells the gRPC library to run in verbose mode. By default when
this environment variable is used the debug version of the gRPC library will be used, if the library can not be found the execution will
fail.
