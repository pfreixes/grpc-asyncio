import os
import os.path
import re
import shutil
import subprocess
import sys

from Cython.Build import cythonize
from setuptools import setup, Extension


if sys.platform in ('win32', 'cygwin', 'cli'):
    raise RuntimeError('grpc-asyncio does not support Windows at the moment')

vi = sys.version_info
if vi < (3, 5):
    raise RuntimeError('grpc-asyncio requires Python 3.5 or greater')


LIBGRPC_DIR = os.path.join(os.path.dirname(__file__), 'vendor', 'grpc')


extensions = [
    Extension(
        "grpc_asyncio.grpc",
        ["grpc_asyncio/grpc.pyx"],
        include_dirs=[
            os.path.join(LIBGRPC_DIR, 'include'),
            os.path.join(LIBGRPC_DIR)
        ],
        library_dirs=[
            os.path.join(LIBGRPC_DIR, 'libs', 'opt')
        ],
        libraries=['grpc'],
        extra_compile_args=["-std=c++11"]
    )
]

dev_requires = [
    "Cython==0.29.4",
    "pytest==4.2.0",
    "pytest-asyncio==0.10.0",
    "grpcio==1.19.0",
    "grpcio-tools==1.19.0",
    "uvloop==0.12.2"
]

setup(
    name='grpc-asyncio',
    description='Native asyncio implementation for gRPC',
    url='http://github.com/pfreixes/grpc-asyncio',
    author='Pau Freixes',
    author_email='pfriexes@gmail.com',
    platforms=['*nix'],
    packages=['grpc_asyncio'],
    ext_modules=cythonize(extensions),
    extras_require={
        "dev": dev_requires
    },
)
