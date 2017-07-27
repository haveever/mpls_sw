BMV2_TOFINO_DEMO_DIR=$(PWD)
TARGET := bmv2_tofino_demo

#CC := 

PLATFROM=
	
LOCAL_INC=../install/include/

SDE_INC=$(SDE_INSTALL)/include/
SDE_LIB=$(SDE_INSTALL)/lib/

ifeq ($(PLATFROM),BMV2)
	LOCAL_LIB=../install/lib/bmpd/l4_lb/
	LIBS := -lpd -lbmpdfixedthrift -lbmpdfixed -lthrift -lpthread -ldl
else
	LOCAL_LIB=../install/lib/tofinobmpd/l4_lb/
	LIBS := -lpd -ltofinobmpdfixedthrift -ltofinobmpdfixed -lthrift -lpthread -ldl
endif

CFLAG := -I$(LOCAL_INC) -I$(SDE_INC)
CFLAG += -g -Wall

LDFLAG := -L$(LOCAL_LIB) -L$(SDE_LIB)

SOURCE_FILES :=	main.c bmv2_init.c

$(TARGET): $(SOURCE_FILES)
	$(CC) $(CFLAG) $(LDFLAG)  $^ -o $@ $(LIBS)


.PHONY : clean
clean:
	-rm $(TARGET)
