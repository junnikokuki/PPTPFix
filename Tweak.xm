#include <substrate.h>

static signed int (*orig_options_from_controller)();

signed int new_options_from_controller() {
	return 1;
}

static void (*orig_die)(int reason);

void new_die(int reason) {
	remove("/private/etc/ppp/postoptions");
	return orig_die(reason);
}

%hookf(FILE*, fdopen, int fd, const char *mode) {
	FILE* f = %orig;
	
	NSMutableString *controlStr = [NSMutableString string];
	NSMutableString *dataStr = [NSMutableString string];
	BOOL isControl = NO;
	BOOL isData = NO;
	
	int c;
	while((c = getc(f)) != -1) {
		if (c == 91) {//[
			isControl = YES;
			[controlStr setString:@""];
		} else if (c == 93) {//]
			isControl = NO;
			if ([controlStr isEqualToString:@"OPTIONS"]) {
				isData = YES;
			} else if ([controlStr isEqualToString:@"EOP"]) {
				break;
			}
		} else {
			if (isControl) {
				[controlStr appendFormat:@"%c", c];
			} else if (isData) {
				[dataStr appendFormat:@"%c", c];
			}
		}
	}
	
	if ([dataStr rangeOfString:@"plugin \"L2TP.ppp\""].location != NSNotFound && [dataStr rangeOfString:@"l2tpipsecsharedsecret \"PPTP\""].location != NSNotFound) {
		[dataStr replaceOccurrencesOfString:@"plugin \"L2TP.ppp\"" withString:@"plugin \"PPTP.ppp\"" options:0 range:NSMakeRange(0, [dataStr length])];
		[dataStr replaceOccurrencesOfString:@"l2tpipsecsharedsecret \"PPTP\"" withString:@"" options:0 range:NSMakeRange(0, [dataStr length])];
		[dataStr replaceOccurrencesOfString:@"l2tpudpport 0" withString:@"" options:0 range:NSMakeRange(0, [dataStr length])];
		[dataStr replaceOccurrencesOfString:@"noccp" withString:@"" options:0 range:NSMakeRange(0, [dataStr length])];
	
		[dataStr replaceOccurrencesOfString:@"mtu 1280" withString:@"mtu 1448" options:0 range:NSMakeRange(0, [dataStr length])];
		
		if ([dataStr characterAtIndex:[dataStr length] - 1] != 32) {
			[dataStr appendFormat:@"%c", 32];
		}
		
		[dataStr appendString:@"refuse-pap refuse-chap-md5 pptp-tcp-keepalive 20 mppe-stateless mppe-40 mppe-128 "];
		
		NSLog(@"#############pppd options changed");
	}
	
	FILE *op = fopen("/private/etc/ppp/postoptions", "w");
	if (op) {
		const char *data = [dataStr UTF8String];
		fwrite(data, strlen(data), 1, op);
		fclose(op);
	}
	
	return f;
}

%ctor {
	@autoreleasepool {
		MSHookFunction((void*)MSFindSymbol(NULL, "_options_from_controller"), (void *)new_options_from_controller, (void **)&orig_options_from_controller);
		MSHookFunction((void*)MSFindSymbol(NULL, "_die"), (void *)new_die, (void **)&orig_die);
		
		%init;
	}
}