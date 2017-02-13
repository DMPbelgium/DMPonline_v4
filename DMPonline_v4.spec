Name: DMPonline_v4
Summary: DMPonline_v4 installation for ugent
License: MIT
Version: 1.0
Release: X
BuildArch: noarch
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires: Percona-Server-server-55
Requires: Percona-Server-client-55
Requires: Percona-Server-devel-55
Requires: httpd
Requires: libcurl-devel
Requires: git
Requires: libXrender
Requires: libXext
Requires: libjpeg-turbo
Requires: libpng
Requires: fontconfig
#already required in gem 'wkhtmltopdf-binary'
#Requires: wkhtmltox
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
%defattr(-,dmponline,dmponline,-)
/opt/%{name}/
/var/log/%{name}/
%attr(0664,root,root) /opt/%{name}/.ruby-version
%attr(0664,root,root) /opt/%{name}/.ruby-gemset
%attr(644,root,root) /opt/%{name}/cron.d/dmponline.cron

%doc

%post
( bash /opt/%{name}/postinstall.sh ) || exit 1

%preun

%changelog
