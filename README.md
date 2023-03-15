# gentoo-prefix-tester

Test gentoo-prefix on different operating systems using vagrant in GitHub Actions CI.


[![gentoo](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/gentoo.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/gentoo.yml)

[![debian11](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/debian11.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/debian11.yml)

[![ubuntu1804](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/ubuntu1804.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/ubuntu1804.yml)

[![ubuntu2204](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/ubuntu2204.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/ubuntu2204.yml)

# Why

- often works on gentoo, but not on other systems
- I tried to install it a few times and kept running into issues
- gentoo-prefix is non trivial and depends on the underlying system

# Idea

- [x] Use vagrant+virtualbox to simulate pure OS instead of docker containers (-> Github CI/Actions only have vagrant for MacOS)
- [x] Regularly run to keep checking ::gentoo tree
- [x] Upload full log and specific failed package log as artifacts
- [x] Automatic reports to gentoo bugzilla using pybugz (analogous to https://github.com/toralf/tinderbox)  
  - Careful detection of already (automatic) submitted bugs, i.e. just append a message if prefix fails for another system (debianX, ubuntuX, ...)
- [x] Test both unstable and stable gentoo(-prefix)


# Issues

* Timeout after ~6h
