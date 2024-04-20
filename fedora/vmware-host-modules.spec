%global prjname vmware-host-modules
%global pkgver MAKEFILE_PKGVER
%global commithash MAKEFILE_COMMITHASH

Name:           vmware-host-modules
Version:        1.0.%{pkgver}
Release:        git%{commithash}
Summary:        Kernel module (kmod) for %{prjname}
License:        GPL-2.0
URL:            https://github.com/mkubecek/vmware-host-modules
Source0:        vmware-host-modules.conf

# For kmod package
Provides:       %{name}-kmod-common = %{version}-%{release}
Requires:       %{name}-kmod >= %{version}

BuildArch:      noarch

%description
%{prjname} kernel module

%prep

%build
# Nothing to build

%install

install -D -m 0644 %{SOURCE0} %{buildroot}%{_modulesloaddir}/vmware-host-modules.conf

%files
%{_modulesloaddir}/vmware-host-modules.conf

%changelog
* Sat Apr 20 2024 j-pai <jesse.pai@gmail.com> - %{version}
- AKMOD Support
