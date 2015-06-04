Name: DMPonline_v4_ugent
Summary: Adaption/fix for DMPonline_v4
License: MIT
Version: 0.1
Release: X
BuildArch: noarch
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires: mysql, mysql-devel, mysql-server
#Requires: wkhtmltopdf
Source: %{name}.tar.gz

%description

%prep
%setup -q -n %{name}

%build
echo "nothing to build"

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/opt/%{name}/tmp
mkdir -p %{buildroot}/var/log/%{name}

cp -r $RPM_BUILD_DIR/%{name}/* %{buildroot}/opt/%{name}/
cp $RPM_BUILD_DIR/%{name}/.ruby-version %{buildroot}/opt/%{name}/.ruby-version
cp $RPM_BUILD_DIR/%{name}/.ruby-gemset %{buildroot}/opt/%{name}/.ruby-gemset

echo "Complete!"

%clean
rm -rf %{buildroot}

%files
%defattr(0755,dmponline,dmponline,-)
/opt/%{name}/
%dir %attr(0775,dmponline,dmponline) /var/log/%name

%doc

%pre
/usr/bin/getent group dmponline || /usr/sbin/groupadd -r dmponline
/usr/bin/getent passwd dmponline || /usr/sbin/useradd -r -d /opt/dmponline -g dmponline -s /bin/false dmponline

%post
( cd /opt/%{name} && bash postinstall.sh ) || exit 1

%preun

%changelog
