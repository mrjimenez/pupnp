/*
 * This wrapper intentionally builds uri.c into the test binary.
 *
 * Why this exists:
 * - parse_uri() is internal (declared in upnp/src/inc/uri.h), not part of
 *   the public Upnp* API that unit tests usually exercise via libupnp.
 * - Shared-library builds do not reliably export parse_uri(), so a test that
 *   only links with libupnp may not resolve this symbol.
 * - Compiling uri.c through a test-local translation unit avoids autotools
 *   object/dependency naming conflicts while keeping the library API surface
 *   unchanged.
 */
#include "../src/genlib/net/uri/uri.c"
