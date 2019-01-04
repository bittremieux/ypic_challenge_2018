# distutils: language = c++
# distutils: sources = SpectrumMatch.cpp

import cython
import numpy as np
cimport numpy as np
from libcpp cimport bool as bool_t
from libcpp.utility cimport pair
from libcpp.vector cimport vector


cdef extern from 'SpectrumMatch.h' namespace 'spectral_network':
    cdef cppclass Spectrum:
        Spectrum(double, unsigned int, unsigned int,
                 np.float32_t*, np.float32_t*, np.uint8_t*) except +

    cdef cppclass SpectrumSpectrumMatch:
        SpectrumSpectrumMatch() nogil except +
        double getScore() nogil
        vector[pair[uint, uint]]* getPeakMatches() nogil

    cdef cppclass SpectrumMatcher:
        SpectrumMatcher() nogil except +
        SpectrumSpectrumMatch* dot(Spectrum*, Spectrum*, double, bool_t) nogil


@cython.boundscheck(False)
@cython.wraparound(False)
def spectral_network(spectra, fragment_mz_tolerance, allow_shift=True):
    cdef double fragment_mz_tolerance_c
    cdef bool_t allow_shift_c
    fragment_mz_tolerance_c = fragment_mz_tolerance
    allow_shift_c = allow_shift

    cdef vector[Spectrum*] spectra_c
    cdef np.float32_t[:] mz, intensity
    cdef np.uint8_t[:] charge
    cdef unsigned int index1, index2
    cdef pair[pair[uint, uint], float] ssm_score
    cdef vector[pair[pair[uint, uint], float]] ssm_scores
    try:
        # Convert each spectrum to a C++ object.
        for spectrum in spectra:
            mz = spectrum.mz
            intensity = spectrum.intensity
            charge = np.zeros(len(spectrum.mz), dtype=np.uint8)
            spectra_c.push_back(new Spectrum(
                    spectrum.precursor_mz, spectrum.precursor_charge,
                    len(spectrum.mz),
                    &mz[0], &intensity[0], &charge[0]))

        # Match all spectra with each other.
        with nogil:
            spectrum_matcher = new SpectrumMatcher()
            index1 = 0
            index2 = 0
            for spectrum1 in spectra_c:
                for spectrum2 in spectra_c:
                    if index1 != index2:
                        match_result = spectrum_matcher.dot(
                            spectrum1, spectrum2, fragment_mz_tolerance_c,
                            allow_shift_c)
                        ssm_score.first.first = index1
                        ssm_score.first.second = index2
                        ssm_score.second = match_result.getScore()
                        ssm_scores.push_back(ssm_score)

                        del match_result
                    index2 += 1

                index1 += 1
                index2 = 0
            del spectrum_matcher

        return ssm_scores

    finally:
        for i in range(spectra_c.size()):
            del spectra_c[i]
        spectra_c.clear()
