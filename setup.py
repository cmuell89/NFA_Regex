from distutils.core import setup
from Cython.Build import cythonize

setup(
  name = 'NFA',
  ext_modules = cythonize("NFA.pyx"),
)