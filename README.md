# Dataset of packed PE files

This is a fork of the dataset at [https://github.com/chesvectain/PackingData](https://github.com/chesvectain/PackingData) with some samples sanitized (e.g. UPX-packed samples in the ´not-packed´ folder or samples with a same hash from the packer and `not-packed` folders). It also includes a folder named `outliers` containing samples we could identify as potentially disturbing our models, i.e. when they were sorted among the not packed samples while demonstrating characteristics of packed data. This dataset can be used for training machine learning models tailored to PE executable packing.


## :star: Related Projects

You may also like these:

- [Awesome Executable Packing](https://github.com/packing-box/awesome-executable-packing): A curated list of awesome resources related to executable packing.
- [Bintropy](https://github.com/packing-box/bintropy): Analysis tool for estimating the likelihood that a binary contains compressed or encrypted bytes.
- [Dataset of packed ELF files](https://github.com/packing-box/dataset-packed-elf): Dataset of ELF samples packed with many different packers.
- [Docker Packing Box](https://github.com/packing-box/docker-packing-box): Docker image gathering packers and tools for making datasets of packed executables.
- [PEiD](https://github.com/packing-box/peid): Python implementation of the Packed Executable iDentifier (PEiD).
- [PyPackerDetect](https://github.com/packing-box/PyPackerDetect): Packing detection tool for PE files.

Example of visualization created with [Bintropy](https://github.com/packing-box/bintropy):

<p align="center"><img src="https://raw.githubusercontent.com/packing-box/docker-packing-box/main/docs/imgs/calc.png"></p>

