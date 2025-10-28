package version

var (
	// Overridden at build time with: -ldflags "-X github.com/repsejnworb/cpout/internal/version.version=v1.2.3"
	version = "dev"
)

func String() string { return version }
