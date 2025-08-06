# gentoo-prefix-tester

## Gentoo Bugzilla

[Open Bugs](https://bugs.gentoo.org/buglist.cgi?component=Prefix%20Support&email1=apn-pucky@gentoo.org&emailreporter1=1&emailtype1=substring&f1=reporter&list_id=6844761&o1=equals&query_format=advanced&resolution=---&short_desc=bootstrap-prefix.sh%20fails&short_desc_type=allwordssubstr&v1=%25user%25)

[Resolved Bugs](https://bugs.gentoo.org/buglist.cgi?bug_status=RESOLVED&component=Prefix%20Support&email1=apn-pucky@gentoo.org&emailcc1=1&emailtype1=substring&f1=reporter&list_id=6844770&o1=equals&query_format=advanced&v1=%25user%25)

## Status

[![docker-debian-13](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/docker-debian-13.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/docker-debian-13.yml)

[![local-macos-latest](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/local-macos-latest.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/local-macos-latest.yml)

[![local-ubuntu-24.04](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/local-ubuntu-24.04.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/local-ubuntu-24.04.yml)

[![vagrant-gentoo](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/vagrant-gentoo.yml/badge.svg)](https://github.com/APN-Pucky/gentoo-prefix-tester/actions/workflows/vagrant-gentoo.yml)


## Test map

Test gentoo-prefix on different operating systems using vagrant in GitHub Actions CI.

Most of the failure are due to the 6h CI limit.

Pleas check the Actions tab for the latest results.


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

* Github CI times out after ~6h = 360min

# Related

* https://github.com/awesomebytes/gentoo_prefix_ci
* https://wiki.gentoo.org/wiki/Google_Summer_of_Code/2023/Ideas/Better_testing_infrastructure_for_Gentoo_Prefix
