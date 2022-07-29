Name:           guihive
Version:        1.1
Release:        1%{?dist}
Summary:        guiHive - A Graphical User Interface for the eHive Production System

License:        Apachev2
URL:            https://github.com/Ensembl/guihive
Source0:        file://$HOME/pkgbuild/guihive.tgz
Source1:        file://$HOME/pkgbuild/guihive.service
Source2:        file://$HOME/pkgbuild/80-guihive.preset

Patch0:		guihive-server.patch

BuildRequires:  make
BuildRequires:  git
%{?systemd_requires}
BuildRequires:  systemd

Requires(pre): shadow-utils

Requires: graphviz
Requires: perl-GraphViz
Requires: perl-Capture-Tiny
Requires: perl-DBI
Requires: perl-DBD-MySQL
Requires: perl-HTML-Parser
Requires: perl-HTML-Template
Requires: perl-JSON
Requires: perl-JSON-PP
Requires: perl-Net-Daemon
Requires: perl-PlRPC
Requires: perl-Proc-Daemon = 0.23
Requires: perl-Sub-Uplevel
Requires: perl-Time-Piece
Requires: perl-URI
Requires: epel-release

%description
guiHive is a web-based interface to eHive.

%prep
%setup -q -n guihive
%patch0 -p1

%build
make %{?_smp_mflags}

%install
%make_install
install -D -m 644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service
install -D -m 644 %{SOURCE2} %{buildroot}%{_presetdir}/80-%{name}.preset

%pre
getent group guihive >/dev/null || groupadd -r guihive
getent passwd guihive >/dev/null || \
    useradd -r -g guihive -d /usr/local/share/guihive/ -s /sbin/nologin \
    -c "User to run the guihive service" guihive
exit 0

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun %{name}.service

%files
/usr/lib/systemd/system-preset/80-guihive.preset
/usr/lib/systemd/system/guihive.service
/usr/local/bin/guihive-server
/usr/local/share/guihive/

%changelog
* Thu Jul 28 2022 Arne Becker <arne@ebi.ac.uk> - 1.1-1
- Set up guihive as systemd service
* Tue May 10 2022 Arne Becker <arne@ebi.ac.uk> - 1.0-1
- guihive, initial RPM package
