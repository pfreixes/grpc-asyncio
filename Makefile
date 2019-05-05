_default: compile


clean:
	rm -fr grpc_asyncio/*.c grpc_asyncio/*.cpp grpc_asyncio/*.so
	find . -name '__pycache__' | xargs rm -rf
	find . -type f -name "*.pyc" -delete

setup-build:
	python setup.py build_ext --inplace

install:
	pip install -e .

install-dev:
	pip install -e ".[dev]"

compile: clean setup-build

acceptance:
ifeq ($(DEBUG),True)
	GRPC_TRACE=all GRPC_VERBOSITY=DEBUG DYLD_LIBRARY_PATH=`pwd`/vendor/grpc/libs/dbg PYTHONASYNCIODEBUG=1 pytest -sv tests/acceptance
else
	DYLD_LIBRARY_PATH=`pwd`/vendor/grpc/libs/opt pytest -sv tests/acceptance
endif

build-fixtures:
	python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. tests/acceptance/fixtures/echo.proto

test: acceptance


.PHONY: clean setup-build install install-dev compile acceptance test
