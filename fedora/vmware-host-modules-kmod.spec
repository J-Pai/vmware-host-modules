%if 0%{?fedora}
%global buildforkernels akmod
%global debug_package %{nil}
%endif

%global prjname vmware-host-modules
%global pkgver MAKEFILE_PKGVER
%global commithash MAKEFILE_COMMITHASH
%define buildforkernels akmod

Name:           %{prjname}-kmod
Version:        1.0.%{pkgver}
Release:        git%{commithash}
Summary:        Kernel module (kmod) for %{prjname}
License:        GPL-2.0
URL:            https://github.com/mkubecek/vmware-host-modules
Source0:        vmware-host-modules-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-root-%(%{__id_u} -n)


BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  elfutils-libelf-devel
BuildRequires:  kmodtool
Conflicts:      vmware-host-modules-kmod-common

%{expand:%(kmodtool --target %{_target_cpu} --kmodname %{prjname} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null) }

%description
%{prjname} kernel module

%prep
kmodtool --target %{_target_cpu} --kmodname %{prjname} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null

%autosetup -n vmware-host-modules-%{version}

for kernel_version in %{?kernel_versions} ; do
    cp -a vmware-host-modules _kmod_build_${kernel_version%%___*}
done

%build
for kernel_version in %{?kernel_versions}; do
    make %{?_smp_mflags} -C "${PWD}/_kmod_build_${kernel_version%%___*}" M=${PWD}/_kmod_build_${kernel_version%%___*} \
    VM_UNAME=${kernel_version%%___*}
done

%install
for kernel_version in %{?kernel_versions}; do
  make %{?_smp_mflags} -C "${PWD}/_kmod_build_${kernel_version%%___*}" M=${PWD}/_kmod_build_${kernel_version%%___*} \
    KMOD_INSTALL_DIR=%{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix} \
    VM_UNAME=${kernel_version%%___*} akmod/akmod-install
done
%{?akmod_install}

%changelog
* Sat Apr 20 2024 j-pai <jesse.pai@gmail.com> - %{version}
- AKMOD Support
