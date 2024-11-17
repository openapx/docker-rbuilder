

# -- scaffolding
save_sources_to <- "/sources/packages"

if ( ! dir.exists( save_sources_to ) && ! dir.create( save_sources_to, recursive = TRUE ) )
  stop("Could not create ", save_sources_to )



# -- identify packages spec
xspec <- "/opt/openapx/config/rbuilder/packages"


# -- deploy specification

# - initialize vector of packages
pckgs <- character(0)

# - import spec
lst <- try( base::suppressWarnings( readLines( con = xspec ) ) )

if ( inherits( lst, "try-error") )
  stop( "Failed to read sepcification ", basename(xspec) )

pckgs <- lst[ which( trimws(lst) != "" & ! grepl( "^#", trimws(lst), perl = TRUE ) ) ]

# - install
#   note: for other than packages ... we install one at a time
#   note: the spec order is important in packages-<whatever>

install.packages( pckgs[ ! pckgs %in% row.names( installed.packages( lib.loc = head(.libPaths(), n = 1) ) ) ], type = "source", destdir = "/sources/packages", INSTALL_opts = "--install-tests" )


# - generate checksums
#   note: use list of sources to identify what packages were installed

#   note: making sure digest is installed ...
if ( ! "digest" %in% row.names( installed.packages() ) ) 
  install.packages( "digest", type = "source", destdir = "/sources/packages", INSTALL_opts = "--install-tests" )


algos <- c( "md5", "sha256" ) # our hash algorithms

for ( xitem in list.dirs( head(.libPaths(), n = 1), recursive = FALSE, full.names = TRUE ) )
  if ( file.exists( file.path(xitem, "DESCRIPTION") ) &&
       ! all( file.exists( file.path(xitem, algos) ) ) )
    for( y in algos ) {

      flst <- list.files( xitem, recursive = TRUE, full.names = FALSE )

      hashes <- sapply( flst[ ! flst %in% algos ] , function( f, hash = y, root = xitem ) {
        digest::digest( file.path( root, f), algo = hash, file = TRUE )
      }, USE.NAMES = TRUE )

      lst <- sapply( sort(names(hashes)), function( x ) {
        paste( hashes[x], x, sep = "  " )  # note: two spaces is important
      } )

      writeLines( lst, con = file.path( xitem, y ) )  # note: should produce a file <algo> in the root of the package install
    }

}

