all: clean generate

ASN1_C_DIR=asn-c-generated
ACN_C_DIR=acn-c-generated

ASN1_ADA_DIR=asn-ada-generated
ACN_ADA_DIR=acn-ada-generated

CC=gcc
GNATMAKE=gnatmake

generate:
	mkdir -p $(ASN1_C_DIR)
	mkdir -p $(ACN_C_DIR)
	asn1.exe -o $(ASN1_C_DIR) -uPER -c protocol.asn
	asn1.exe -o $(ACN_C_DIR) -ACN -c protocol.acn protocol.asn
	mkdir -p $(ASN1_ADA_DIR)
	mkdir -p $(ACN_ADA_DIR)
	asn1.exe -o $(ASN1_ADA_DIR) -uPER -Ada protocol.asn
	asn1.exe -o $(ACN_ADA_DIR) -ACN -Ada protocol.acn protocol.asn

compile:
	$(CC) $(CFLAGS) -I$(ACN_C_DIR) -o encode src/encode.c $(ACN_C_DIR)/asn1crt.c $(ACN_C_DIR)/protocol.c $(ACN_C_DIR)/acn.c $(ACN_C_DIR)/ber.c $(ACN_C_DIR)/xer.c $(ACN_C_DIR)/real.c
	$(CC) $(CFLAGS) -I$(ACN_C_DIR) -o decode src/decode.c $(ACN_C_DIR)/asn1crt.c $(ACN_C_DIR)/protocol.c $(ACN_C_DIR)/acn.c $(ACN_C_DIR)/ber.c $(ACN_C_DIR)/xer.c $(ACN_C_DIR)/real.c
	$(GNATMAKE) -gnatc $(ACN_ADA_DIR)/myprotocol.adb

clean:
	rm -rf $(ASN1_C_DIR) $(ACN_C_DIR)
	rm -rf $(ASN1_ADA_DIR) $(ACN_ADA_DIR)
	rm  -f *~ encode decode
	rm  -f src/*~ encode decode
	rm -rf encoded.sample
