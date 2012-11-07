#!/bin/bash
./runspecS6H1beforeHann |  grep 'Real' | cut -f '2' -d '=' > beforeHannReal.txt
./runspecS6H1beforeHann |  grep 'Imaginary' | cut -f '2' -d '=' > beforeHannImaginary.txt
./runspecS6H1beforeTukey |  grep 'Real' | cut -f '2' -d '=' > beforeTukeyReal.txt
./runspecS6H1beforeTukey |  grep 'Imaginary' | cut -f '2' -d '=' > beforeTukeyImaginary.txt
./runspecS6H1afterHann |  grep 'Real' | cut -f '2' -d '=' > afterHannReal.txt
./runspecS6H1afterHann |  grep 'Imaginary' | cut -f '2' -d '=' > afterHannImaginary.txt
./runspecS6H1afterTukey |  grep 'Real' | cut -f '2' -d '=' > afterTukeyReal.txt
./runspecS6H1afterTukey |  grep 'Imaginary' | cut -f '2' -d '=' > afterTukeyImaginary.txt
