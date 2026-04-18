#include "ithread.h"
#include "upnp.h"
#include "upnpdebug.h"
#include "uri.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* parse_hostport() in uri.c uses this global for IPv6 scope IDs. */
unsigned gIF_INDEX = (unsigned)-1;
ithread_rwlock_t GlobalHndRWLock;

void UpnpPrintf(Upnp_LogLevel DLevel,
	Dbg_Module Module,
	const char *DbgFileName,
	int DbgLineNo,
	const char *FmtStr,
	...)
{
	(void)DLevel;
	(void)Module;
	(void)DbgFileName;
	(void)DbgLineNo;
	(void)FmtStr;
}

struct test_case
{
	const char *uri;
	int expected;
	int line;
};

#define TEST_INVALID_PORT(URI_VALUE) \
	{.uri = URI_VALUE, .expected = UPNP_E_INVALID_URL, .line = __LINE__}

static int run_test(const struct test_case *tc)
{
	uri_type parsed;
	int ret = parse_uri(tc->uri, strlen(tc->uri), &parsed);

	if (ret == tc->expected) {
		return 0;
	}

	printf("%s:%d parse_uri('%s') returned %d, expected %d\n",
		__FILE__,
		tc->line,
		tc->uri,
		ret,
		tc->expected);
	return 1;
}

int main(void)
{
	int i;
	int failures = 0;
	static const struct test_case tests[] = {
		TEST_INVALID_PORT("http://127.0.0.1:65536/"),
		TEST_INVALID_PORT("http://127.0.0.1:65537/"),
		TEST_INVALID_PORT("http://127.0.0.1:131073/"),
		TEST_INVALID_PORT("http://127.0.0.1:-1/"),
		TEST_INVALID_PORT("http://127.0.0.1:-65535/"),
	};

	for (i = 0; i < (int)(sizeof(tests) / sizeof(tests[0])); i++) {
		failures += run_test(&tests[i]);
	}

	return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
