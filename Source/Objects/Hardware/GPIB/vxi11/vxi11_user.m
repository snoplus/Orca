/* Revision history: */
/* $Id: vxi11_user.cc,v 1.13 2007/10/09 08:42:57 sds Exp $ */
/*
 * $Log: vxi11_user.cc,v $
 * Revision 1.13  2007/10/09 08:42:57  sds
 * Minor change to vxi11_receive_data_block(), this fn now
 * copes with instruments that return just "#0" (for whatever
 * reason). Suggestion by Jarek Sadowski.
 *
 * Revision 1.12  2007/08/31 10:32:39  sds
 * Bug fix in vxi11_receive(), to ensure that no more than "len"
 * bytes are ever received (and so avoiding a segmentation fault).
 * This was a bug introduced in release 1.04 (RCS 1.10) whilst
 * making some other changes to the vxi11_receive() fn. Many thanks
 * to Rob Penny for spotting the bug and providing a patch.
 *
 * Revision 1.11  2007/07/10 13:49:18  sds
 * Changed the vxi11_open_device() fn to accept a third argument, char *device.
 * This gets passed to the core vxi11_open_device() fn (the one that deals with
 * separate clients and links), and the core vxi11_open_link() fn; these two
 * core functions have also had an extra parameter added accordingly. In order
 * to not break the API, a wrapper function is provided in the form of the
 * original vxi11_open_device() fn, that just takes 2 arguments
 * (char *ip, CLINK *clink), this then passes "inst0" as the device argument.
 * Backwards-compatible wrappers for the core functions have NOT been provided.
 * These are generally not used from userland anyway. Hopefully this won't
 * upset anyone!
 *
 * Revision 1.10  2007/07/10 11:12:12  sds
 * Patches provided by Robert Larice. This basically solves the problem
 * of having to recreate a link each time you change client. In the words
 * of Robert:
 *
 * ---------
 * In the source code there were some strange comments, suggesting
 * you had trouble to get more than one link working.
 *
 * I think thats caused by some misuse of the rpcgen generated subroutines.
 * 1) those rpcgen generated *_1 functions returned pointers to
 *      statically allocated temporary structs.
 *    those where meant to be instantly copied to the user's space,
 *    which wasn't done, thus instead of
 *        Device_ReadResp  *read_resp;
 *        read_resp = device_read_1(...)
 *    one should have written someting like:
 *        Device_ReadResp  *read_resp;
 *        read_resp = malloc(...)
 *        memcpy(read_resp, device_read_1(...), ...)
 * 2) but a better fix is to use the rpcgen -M Flag
 *   which allows to pass the memory space as a third argument
 * so one can write
 *       Device_ReadResp  *read_resp;
 *        read_resp = malloc(...)
 *        device_read_1(..., read_resp, ...)
 *      furthermore this is now automatically thread save
 * 3) the rpcgen function device_read_1
 * expects a target buffer to be passed via read_resp
 * which was not done.
 * 4) the return value of vxi11_receive() was computed incorrectly
 * 5) minor,  Makefile typo's
 * ---------
 * So big thanks to Robert Larice for the patch! I've tested it
 * (briefly) on more than one scope, and with multiple links per
 * client, and it seems to work fine. I've thus removed all references
 * to VXI11_ENABLE_MULTIPLE_CLIENTS, and deleted the vxi11_open_link()
 * function that WASN'T passed an ip address (that was only called
 * from the vxi11_send() fn, when there was more than one client).
 *
 * Revision 1.9  2006/12/08 12:06:58  ijc
 * Basically the same changes as revision 1.8, except replace all
 * references to "vxi11_receive" with "vxi11_send" and all references
 * to "-VXI11_NULL_READ_RESP" with "-VXI11_NULL_WRITE_RESP".
 *
 * Revision 1.8  2006/12/07 12:22:20  sds
 * Couple of changes, related.
 * (1) added extra check in vxi11_receive() to see if read_resp==NULL.
 * read_resp can apparently be NULL if (eg) you send an instrument a
 * query, but the instrument is so busy with something else for so int32_t
 * that it forgets the original query. So this extra check is for that
 * situation, and vxi11_receive returns -VXI11_NULL_READ_RESP to the
 * calling function.
 * (2) vxi11_send_and_receive() is now aware of the possibility of
 * being returned -VXI11_NULL_READ_RESP. If so, it re-sends the query,
 * until either getting a "regular" read error (read_resp->error!=0) or
 * a successful read.
 *
 * Revision 1.7  2006/12/06 16:27:47  sds
 * removed call to ANSI free() fn in vxi11_receive, which according to
 * Manfred Scheible "is not necessary and wrong (crashes)".
 *
 * Revision 1.6  2006/08/25 13:45:12  sds
 * Major improvements to the vxi11_send function. Now takes
 * link->maxRecvSize into account, and writes a chunk at a time
 * until the entire message is sent. Important for sending large
 * data sets, because the data you want to send may be larger than
 * the instrument's "input buffer."
 *
 * Revision 1.5  2006/08/25 13:06:44  sds
 * tidied up some of the return values, and made sure that if a
 * sub-function returned an error value, this would also be
 * returned by the calling function.
 *
 * Revision 1.4  2006/07/06 13:04:59  sds
 * Lots of changes this revision.
 * Found I was having problems talking to multiple links on the same
 * client, if I created a different client for each one. So introduced
 * a few global variables to keep track of all the ip addresses of
 * clients that the library is asked to create, and only creating new
 * clients if the ip address is different. This puts a limit of how
 * many unique ip addresses (clients) a single process can connect to.
 * Set this value at 256 (should hopefully be enough!).
 * Next I found that talking to different clients on different ip
 * addresses didn't work. It turns out that create_link_1() creates
 * a static structure. This this link is associated with a given
 * client (and hence a given IP address), then the only way I could
 * think of making things work was to add a call to an
 * vxi11_open_link() function before each send command (no idea what
 * this adds to overheads and it's very messy!) - at least I was
 * able to get this to only happen when we are using more than one
 * client/ip address.
 * Also, while I was at it, I re-ordered the functions a little -
 * starts with core user functions, extra user functions, then core
 * library functions at the end. Added a few more comments. Tidied
 * up. Left some debugging info in, but commented out.
 *
 * Revision 1.3  2006/06/26 12:40:56  sds
 * Introduced a new CLINK structure, to reduce the number of arguments
 * passed to functions. Wrote wrappers for open(), close(), send()
 * and receieve() functions, then adjusted all the other functions built
 * on those to make use of the CLINK structure.
 *
 * Revision 1.2  2006/06/26 10:29:48  sds
 * Added GNU GPL and copyright notices.
 *
 */

/* vxi11_user.cc
 * Copyright (C) 2006 Steve D. Sharples
 *
 * User library for opening, closing, sending to and receiving from
 * a device enabled with the VXI11 RPC ethernet protocol. Uses the files
 * generated by rpcgen vxi11.x.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * The author's email address is steve.sharples@nottingham.ac.uk
 */

#include "vxi11_user.h"

/***************************************************************************** 
 * GENERAL NOTES
 *****************************************************************************
 *
 * There are four functions at the heart of this library:
 *
 * int	vxi11_open_device(char *ip, CLIENT **client, VXI11_LINK **link)
 * int	vxi11_close_device(char *ip, CLIENT *client, VXI11_LINK *link)
 * int	vxi11_send(CLIENT *client, VXI11_LINK *link, char *cmd, uint32_t len)
 * int32_t	vxi11_receive(CLIENT *client, VXI11_LINK *link, char *buffer, uint32_t len, uint32_t timeout)
 *
 * Note that all 4 of these use separate client and link structures. All the
 * other functions are built on these four core functions, and the first layer
 * of abstraction is to combine the CLIENT and VXI11_LINK structures into a
 * single entity, which I've called a CLINK. For the send and receive
 * functions, this is just a simple wrapper. For the open and close functions
 * it's a bit more complicated, because we somehow have to keep track of
 * whether we've already opened a device with the same IP address before (in
 * which case we need to recycle a previously created client), or whether
 * we've still got any other links to a given IP address left when we are 
 * asked to close a clink (in which case we can sever the link, but have to
 * keep the client open). This is so the person using this library from
 * userland does not have to keep track of whether they are talking to a
 * different physical instrument or not each time they establish a connection.
 *
 * So the base functions that the user will probably want to use are:
 *
 * int	vxi11_open_device(char *ip, CLINK *clink)
 * int	vxi11_close_device(char *ip, CLINK *clink)
 * int	vxi11_send(CLINK *clink, char *cmd, uint32_t len)
 *    --- or --- (if sending just text)
 * int	vxi11_send(CLINK *clink, char *cmd)
 * int32_t	vxi11_receive(CLINK *clink, char *buffer, uint32_t len, uint32_t timeout)
 *
 * There are then useful (to me, anyway) more specific functions built on top
 * of these:
 *
 * int	vxi11_send_data_block(CLINK *clink, char *cmd, char *buffer, uint32_t len)
 * int32_t	vxi11_receive_data_block(CLINK *clink, char *buffer, uint32_t len, uint32_t timeout)
 * int32_t	vxi11_send_and_receive(CLINK *clink, char *cmd, char *buf, uint32_t buf_len, uint32_t timeout)
 * int32_t	vxi11_obtain_long_value(CLINK *clink, char *cmd, uint32_t timeout)
 * double vxi11_obtain_double_value(CLINK *clink, char *cmd, uint32_t timeout)
 *
 * (then there are some shorthand wrappers for the above without specifying
 * the timeout due to sheer laziness---explore yourself)
 */


/* Global variables. Keep track of multiple links per client. We need this
 * because:
 * - we'd like the library to be able to cope with multiple links to a given
 *   client AND multiple links to multiple clients
 * - we'd like to just refer to a client/link ("clink") as a single
 *   entity from user land, we don't want to worry about different
 *   initialisation procedures, depending on whether it's an instrument
 *   with the same IP address or not
 */
char	VXI11_IP_ADDRESS[VXI11_MAX_CLIENTS][20];
CLIENT	*VXI11_CLIENT_ADDRESS[VXI11_MAX_CLIENTS];
int	VXI11_DEVICE_NO = 0;
int	VXI11_LINK_COUNT[VXI11_MAX_CLIENTS];

/*****************************************************************************
 * KEY USER FUNCTIONS - USE THESE FROM YOUR PROGRAMS OR INSTRUMENT LIBRARIES *
 *****************************************************************************/

/* OPEN FUNCTIONS *
 * ============== */

/* Use this function from user land to open a device and create a link. Can be
 * used multiple times for the same device (the library will keep track).*/
int	vxi11_open_device(const char *ip, CLINK *clink, char *device) {
	int	ret;
	int	l;
	int	device_no=-1;
	
	//	NSLog(@"before doing anything, clink->link = %d\n", clink->link);
	/* Have a look to see if we've already initialised an instrument with
	 * this IP address */
	for (l=0; l<VXI11_MAX_CLIENTS; l++){
		if (strcmp(ip,VXI11_IP_ADDRESS[l]) == 0 ) {
			device_no=l;
			//			NSLog(@"Open function, search, found ip address %s, device no %d\n",ip,device_no);
		}
	}
	
	/* Couldn't find a match, must be a new IP address */
	if (device_no < 0) {
		/* Uh-oh, we're out of storage space. Increase the #define
		 * for VXI11_MAX_CLIENTS in vxi11_user.h */
		if (VXI11_DEVICE_NO >= VXI11_MAX_CLIENTS) {
			NSLog(@"Error: maximum of %d clients allowed\n",VXI11_MAX_CLIENTS);
			ret = -VXI11_MAX_CLIENTS;
		}
		/* Create a new client, keep a note of where the client pointer
		 * is, for this IP address. Because it's a new client, this
		 * must be link number 1. Keep track of how many devices we've
		 * opened so we don't run out of storage space. */
		else {
			ret = _vxi11_open_device(ip, &(clink->client), &(clink->link), device);
			strncpy(VXI11_IP_ADDRESS[VXI11_DEVICE_NO],ip,20);
			VXI11_CLIENT_ADDRESS[VXI11_DEVICE_NO] = clink->client;
			VXI11_LINK_COUNT[VXI11_DEVICE_NO]=1;
			//			NSLog(@"Open function, could not find ip address %s.\n",ip);
			//			NSLog(@"So now, VXI11_IP_ADDRESS[%d]=%s,\n",VXI11_DEVICE_NO,VXI11_IP_ADDRESS[VXI11_DEVICE_NO]);
			//			NSLog(@"VXI11_CLIENT_ADDRESS[%d]=%d,\n",VXI11_DEVICE_NO,VXI11_CLIENT_ADDRESS[VXI11_DEVICE_NO]);
			//			NSLog(@"          clink->client=%d,\n",clink->client);
			//			NSLog(@"VXI11_LINK_COUNT[%d]=%d.\n",VXI11_DEVICE_NO,VXI11_LINK_COUNT[VXI11_DEVICE_NO]);
			VXI11_DEVICE_NO++;
		}
	}
	/* already got a client for this IP address */
	else {
		/* Copy the client pointer address. Just establish a new link
		 * (not a new client). Add one to the link count */
		clink->client = VXI11_CLIENT_ADDRESS[device_no];
		ret = _vxi11_open_link(ip, &(clink->client), &(clink->link), device);
		//		NSLog(@"Found an ip address, copying client from VXI11_CLIENT_ADDRESS[%d]\n",device_no);
		VXI11_LINK_COUNT[device_no]++;
		//		NSLog(@"Have just incremented VXI11_LINK_COUNT[%d], it's now %d\n",device_no,VXI11_LINK_COUNT[device_no]);
	}
	//	NSLog(@"after creating link, clink->link = %d\n", clink->link);
	return ret;
}


/* CLOSE FUNCTION *
 * ============== */

/* Use this function from user land to close a device and/or sever a link. Can
 * be used multiple times for the same device (the library will keep track).*/
int     vxi11_close_device(const char *ip, CLINK *clink) {
	int     l,ret;
	int     device_no = -1;
	
	/* Which instrument are we referring to? */
	for (l=0; l<VXI11_MAX_CLIENTS; l++){
		if (strcmp(ip,VXI11_IP_ADDRESS[l]) == 0 ) {
			device_no=l;
		}
	}
	/* Something's up if we can't find the IP address! */
	if (device_no == -1) {
		NSLog(@"vxi11_close_device: error: I have no record of you ever opening device\n");
		NSLog(@"                    with IP address %s\n",ip);
		ret = -4;
	}
	else {	/* Found the IP, there's more than one link to that instrument,
	 * so keep track and just close the link */
		if (VXI11_LINK_COUNT[device_no] > 1 ) {
			ret = _vxi11_close_link(ip,clink->client, clink->link);
			VXI11_LINK_COUNT[device_no]--;
		}
		/* Found the IP, it's the last link, so close the device (link
		 * AND client) */
		else {
			ret = _vxi11_close_device(ip, clink->client, clink->link);
            // Make sure to zero out the address.
            VXI11_IP_ADDRESS[device_no][0] = '\0';
            if (device_no == VXI11_DEVICE_NO-1) VXI11_DEVICE_NO--;
		}
	}
	return ret;
}


/* SEND FUNCTIONS *
 * ============== */


/* We still need the version of the function where the length is set explicitly
 * though, for when we are sending fixed length data blocks. */
int	vxi11_send(CLINK *clink, const char *cmd, uint32_t len) {
	return _vxi11_send(clink->client, clink->link, cmd, len);
}


/* RECEIVE FUNCTIONS *
 * ================= */

int32_t	vxi11_receive(CLINK *clink, char *buffer, uint32_t len, uint32_t timeout) {
	return _vxi11_receive(clink->client, clink->link, buffer, len, timeout);
}



/*****************************************************************************
 * USEFUL ADDITIONAL HIGHER LEVER USER FUNCTIONS - USE THESE FROM YOUR       *
 * PROGRAMS OR INSTRUMENT LIBRARIES                                          *
 *****************************************************************************/

/* SEND FIXED LENGTH DATA BLOCK FUNCTION *
 * ===================================== */
int	vxi11_send_data_block(CLINK *clink, const char *cmd, char *buffer, uint32_t len) {
	char	*out_buffer;
	size_t	cmd_len=strlen(cmd);
	int	ret;
	out_buffer= (char*)malloc(cmd_len+10+len);
	NSLog(@"%s %08lu",cmd,len);
	memcpy(out_buffer+cmd_len+10,buffer,(uint32_t) len);
	ret = vxi11_send(clink, out_buffer, (uint32_t) (cmd_len+10+len));
	free( out_buffer);
	return ret;
}


/* RECEIVE FIXED LENGTH DATA BLOCK FUNCTION *
 * ======================================== */

/* This function reads a response in the form of a definite-length block, such
 * as when you ask for waveform data. The data is returned in the following
 * format:
 *   #800001000<1000 bytes of data>
 *   ||\______/
 *   ||    |
 *   ||    \---- number of bytes of data
 *   |\--------- number of digits that follow (in this case 8, with leading 0's)
 *   \---------- always starts with #
 */
int32_t	vxi11_receive_data_block(CLINK *clink, char *buffer, uint32_t len, uint32_t timeout) {
	/* I'm not sure what the maximum length of this header is, I'll assume it's 
	 * 11 (#9 + 9 digits) */
	uint32_t	necessary_buffer_size;
	char		*in_buffer;
	int32_t		ret;
	int		ndigits;
	uint32_t	returned_bytes;
	int		l;
	char		scan_cmd[20];
	necessary_buffer_size=len+12;
	in_buffer= (char*)malloc(necessary_buffer_size);

	ret=vxi11_receive(clink, in_buffer, necessary_buffer_size, timeout);
	if (ret < 0) return ret;
	if (in_buffer[0] != '#') {
		NSLog(@"vxi11_user: data block error: data block does not begin with '#'\n");
		NSLog(@"First 20 characters received were: '");
		for(l=0;l<20;l++) {
			NSLog(@"%c",in_buffer[l]);
		}
		NSLog(@"'\n");
		return -3;
	}
	
	/* first find out how many digits */
	sscanf(in_buffer,"#%1d",&ndigits);
	/* some instruments, if there is a problem acquiring the data, return only "#0" */
	if (ndigits > 0) {
		/* now that we know, we can convert the next <ndigits> bytes into an uint32_t */
		//NSLog(@"#%%1d%%%dlu",ndigits);
		sscanf(in_buffer,scan_cmd,&ndigits,&returned_bytes);
		memcpy(buffer, in_buffer+(ndigits+2), returned_bytes);
		free( in_buffer);
		return (int32_t) returned_bytes;
	}
	else return 0;
}


/* SEND AND RECEIVE FUNCTION *
 * ========================= */

/* This is mainly a useful function for the overloaded vxi11_obtain_value()
 * fn's, but is also handy and useful for user and library use */
int32_t	vxi11_send_and_receive(CLINK *clink, const char *cmd, char *buf, uint32_t buf_len, uint32_t timeout) {
	int	ret;
	int32_t	bytes_returned;
	do {
		ret = (uint32_t)vxi11_send(clink, cmd, (uint32_t)strlen(cmd));
		if (ret != 0) {
			if (ret != -VXI11_NULL_WRITE_RESP) {
				NSLog(@"Error: vxi11_send_and_receive: could not send cmd.\n");
				NSLog(@"       The function vxi11_send returned %d. ",ret);
				return -1;
			}
			else NSLog(@"(Info: VXI11_NULL_WRITE_RESP in vxi11_send_and_receive, resending query)\n");
		}
		
		bytes_returned = vxi11_receive(clink, buf, buf_len, timeout);
		if (bytes_returned <= 0) {
			if (bytes_returned >-VXI11_NULL_READ_RESP) {
				NSLog(@"Error: vxi11_send_and_receive: problem reading reply.\n");
				NSLog(@"       The function vxi11_receive returned %d. ",bytes_returned);
				return -2;
			}
			else NSLog(@"(Info: VXI11_NULL_READ_RESP in vxi11_send_and_receive, resending query)\n");
		}
	} while (bytes_returned == -VXI11_NULL_READ_RESP || ret == -VXI11_NULL_WRITE_RESP);
	return bytes_returned;
}


/* FUNCTIONS TO RETURN A LONG INTEGER VALUE SENT AS RESPONSE TO A QUERY *
 * ==================================================================== */
int32_t	vxi11_obtain_long_value(CLINK *clink, const char *cmd, uint32_t timeout) {
	char	buf[50]; /* 50=arbitrary length... more than enough for one number in ascii */
	memset(buf, 0, 50);
	if (vxi11_send_and_receive(clink, cmd, buf, 50, timeout) != 0) {
		NSLog(@"Returning 0\n");
		return 0;
	}
	return (uint32_t)strtol(buf, (char **)NULL, 10);
}


/* FUNCTIONS TO RETURN A DOUBLE FLOAT VALUE SENT AS RESPONSE TO A QUERY *
 * ==================================================================== */
double	vxi11_obtain_double_value(CLINK *clink, const char *cmd, uint32_t timeout) {
	char	buf[50]; /* 50=arbitrary length... more than enough for one number in ascii */
	double	val;
	memset(buf, 0, 50);
	if (vxi11_send_and_receive(clink, cmd, buf, 50, timeout) != 0) {
		NSLog(@"Returning 0.0\n");
		return 0.0;
	}
	val = strtod(buf, (char **)NULL);
	return val;
}


/*****************************************************************************
 * CORE FUNCTIONS - YOU SHOULDN'T NEED TO USE THESE FROM YOUR PROGRAMS OR    *
 * INSTRUMENT LIBRARIES                                                      *
 *****************************************************************************/

/* OPEN FUNCTIONS *
 * ============== */
int	_vxi11_open_device(const char *inputip, CLIENT **client, VXI11_LINK **link, char *device) {
#ifdef __APPLE__
	char ip[strlen(inputip)];
	strcpy(ip, inputip);
#else
	const char *ip = inputip;
#endif
        char tmp_tcp[] = "tcp";
	*client = clnt_create(ip, DEVICE_CORE, DEVICE_CORE_VERSION, tmp_tcp);
	
	if (*client == NULL) {
		clnt_pcreateerror(ip);
		return -1;
	}
	
	return _vxi11_open_link(ip, client, link, device);
}

int	_vxi11_open_link(const char *inputip, CLIENT **client, VXI11_LINK **link, char *device) {
	
	Create_LinkParms link_parms;
#ifdef __APPLE__
	char ip[strlen(inputip)];
	strcpy(ip, inputip);
#else
	const char *ip = inputip;
#endif


	/* Set link parameters */
	link_parms.clientId	= (int) *client;
	link_parms.lockDevice	= 0;
	link_parms.lock_timeout	= VXI11_DEFAULT_TIMEOUT;
	link_parms.device	= device;
	
	*link = (Create_LinkResp *) calloc(1, sizeof(Create_LinkResp));
#ifdef __APPLE__
	Create_LinkResp * tmp;
	if ((tmp = create_link_1(&link_parms, *client)) == NULL) {
#else
	if (create_link_1(&link_parms, *link, *client) != RPC_SUCCESS) {
#endif
		clnt_perror(*client, ip);
		return -2;
	}
#ifdef __APPLE__
	memcpy(*link, tmp, sizeof(*tmp));
#endif
	return 0;
}


/* CLOSE FUNCTIONS *
 * =============== */
int	_vxi11_close_device(const char *ip, CLIENT *client, VXI11_LINK *link) {
	int	ret;
	
	ret = _vxi11_close_link(ip, client, link);
	
	clnt_destroy(client);
	
	return ret;
}

int	_vxi11_close_link(const char *inputip, CLIENT *client, VXI11_LINK *link) {
	Device_Error dev_error;
#ifdef __APPLE__
	char ip[strlen(inputip)];
	strcpy(ip, inputip);
#else
	const char *ip = inputip;
#endif
	memset(&dev_error, 0, sizeof(dev_error)); 
	
#ifdef __APPLE__
	if (destroy_link_1(&link->lid, client) == NULL) {
#else
	if (destroy_link_1(&link->lid, &dev_error, client) != RPC_SUCCESS) {
#endif
//		clnt_perror(client,ip);
		return -1;
	}
	
	return 0;
}


/* SEND FUNCTIONS *
 * ============== */

/* We still need the version of the function where the length is set explicitly
 * though, for when we are sending fixed length data blocks. */
int	_vxi11_send(CLIENT *client, VXI11_LINK *link, const char *cmd, uint32_t len) {
	Device_WriteParms write_parms;
	int	bytes_left = (int)len;
	
	write_parms.lid			= link->lid;
	write_parms.io_timeout		= VXI11_DEFAULT_TIMEOUT;
	write_parms.lock_timeout	= VXI11_DEFAULT_TIMEOUT;
	
	/* We can only write (link->maxRecvSize) bytes at a time, so we sit in a loop,
	 * writing a chunk at a time, until we're done. */
	do {
		Device_WriteResp write_resp;
		memset(&write_resp, 0, sizeof(write_resp));
		
		if (bytes_left <= link->maxRecvSize) {
			write_parms.flags		= 8;
			write_parms.data.data_len	= bytes_left;
		}
		else {
			write_parms.flags		= 0;
			write_parms.data.data_len	= link->maxRecvSize;
		}
		write_parms.data.data_val	= (char *)cmd + (len - bytes_left);
		
#ifdef __APPLE__
		Device_WriteResp *tmp;
		if((tmp = device_write_1(&write_parms, client)) == NULL) {
#else
		if(device_write_1(&write_parms, &write_resp, client) != RPC_SUCCESS) {
#endif
			return -VXI11_NULL_WRITE_RESP; /* The instrument did not acknowledge the write, just completely
			 dropped it. There was no vxi11 comms error as such, the 
			 instrument is just being rude. Usually occurs when the instrument
			 is busy. If we don't check this first, then the following 
			 line causes a seg fault */
		}
#ifdef __APPLE__
		memcpy(&write_resp, tmp, sizeof(*tmp));
#endif
		if (write_resp . error != 0) {
			NSLog(@"vxi11_user: write error: %d\n",write_resp . error);
			return -(write_resp . error);
		}
		bytes_left -= write_resp . size;
	} while (bytes_left > 0);
	
	return 0;
}


/* RECEIVE FUNCTIONS *
 * ================= */

#define RCV_END_BIT	0x04	// An end indicator has been read
#define RCV_CHR_BIT	0x02	// A termchr is set in flags and a character which matches termChar is transferred
#define RCV_REQCNT_BIT	0x01	// requestSize bytes have been transferred.  This includes a request size of zero.

int32_t _vxi11_receive(CLIENT *client, VXI11_LINK *link, char *buffer, uint32_t len, uint32_t timeout) {
	Device_ReadParms read_parms;
	Device_ReadResp  read_resp;
	int32_t	curr_pos = 0;
	
	read_parms.lid			= link->lid;
	read_parms.requestSize		= (unsigned int)len;
	read_parms.io_timeout		= (unsigned int)timeout;	/* in ms */
	read_parms.lock_timeout		= (unsigned int)timeout;	/* in ms */
	read_parms.flags		= 0;
	read_parms.termChar		= 0;
	
	do {
		memset(&read_resp, 0, sizeof(read_resp));
		
		read_parms.requestSize = (unsigned int)(len  - curr_pos);	// Never request more total data than originally specified in len
#ifdef __APPLE__
		Device_ReadResp *tmp;
		if((tmp = device_read_1(&read_parms, client)) == NULL) {
#else
		read_resp.data.data_val = buffer + curr_pos;
		if(device_read_1(&read_parms, &read_resp, client) != RPC_SUCCESS) {
#endif
	
			return -VXI11_NULL_READ_RESP; /* there is nothing to read. Usually occurs after sending a query
			 which times out on the instrument. If we don't check this first,
			 then the following line causes a seg fault */
		}
#ifdef __APPLE__
		memcpy(&read_resp, tmp, sizeof(*tmp));
                memcpy(buffer + curr_pos, read_resp.data.data_val, read_resp.data.data_len);
#endif
 		if (read_resp . error != 0) {
			/* Read failed for reason specified in error code.
			 *  0     no error
			 *  4     invalid link identifier
			 *  11    device locked by another link
			 *  15    I/O timeout
			 *  17    I/O error
			 *  23    abort
			 */
			
			NSLog(@"vxi11_user: read error: %d\n",read_resp . error);
			return -(read_resp . error);
		}
		
		if((curr_pos + read_resp . data.data_len) <= len) {
			curr_pos += read_resp . data.data_len;
		}
		if( (read_resp.reason & RCV_END_BIT) || (read_resp.reason & RCV_CHR_BIT) ) {
			break;
		}
		else if( curr_pos == len ) {
			NSLog(@"xvi11_user: read error: buffer too small. Read %d bytes without hitting terminator.\n", curr_pos );
			return -100;
		}
	} while(1);
	return (curr_pos); /*actual number of bytes received*/
	
}

