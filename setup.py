import setuptools

import numpy as np

try:
    import Cython.Distutils
except ImportError:
    use_cython = False
else:
    use_cython = True


DISTNAME = 'spectral_network'
AUTHOR = 'Wout Bittremieux'
AUTHOR_EMAIL = 'wout@uw.edu'


compile_args = ['-O3', '-march=native', '-ffast-math',
                '-fno-associative-math', '-std=c++14']
ext_module = setuptools.Extension(
    'spectral_network',
    ['spectral_network.pyx', 'SpectrumMatch.cpp'],
    language='c++', extra_compile_args=compile_args,
    extra_link_args=compile_args, include_dirs=[np.get_include()])

cmdclass = {}
if use_cython:
    cmdclass.update({'build_ext': Cython.Distutils.build_ext})

setuptools.setup(
    name=DISTNAME,
    author=AUTHOR,
    author_email=AUTHOR_EMAIL,
    platforms=['any'],
    cmdclass=cmdclass,
    ext_modules=[ext_module],
)
