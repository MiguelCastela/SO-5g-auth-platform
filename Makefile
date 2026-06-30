CC      = gcc
CFLAGS  = -Iinclude -pthread -g -Wall -Wextra

SRC_DIR   = src
BUILD_DIR = build
BIN_DIR   = bin

DEPS = $(wildcard include/*.h)

# queue.o is shared by all three executables
QUEUE_OBJ = $(BUILD_DIR)/queue.o

# Sources that make up the system manager (5g_auth_platform)
SYSTEM_MANAGER_SRCS = system_manager.c system_initialization.c structures_creation.c \
                      arm_threads.c auth_engine.c general_functions.c clean_up.c \
                      monitor_engine.c
SYSTEM_MANAGER_OBJS = $(addprefix $(BUILD_DIR)/,$(SYSTEM_MANAGER_SRCS:.c=.o)) $(QUEUE_OBJ)

all: $(BIN_DIR)/5g_auth_platform $(BIN_DIR)/mobile_user $(BIN_DIR)/backoffice_user

# Generic compile rule: src/%.c -> build/%.o
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(DEPS) | $(BUILD_DIR)
	$(CC) -c -o $@ $< $(CFLAGS)

$(BIN_DIR)/5g_auth_platform: $(SYSTEM_MANAGER_OBJS) | $(BIN_DIR)
	$(CC) -o $@ $^ $(CFLAGS)

$(BIN_DIR)/mobile_user: $(BUILD_DIR)/mobile_user.o $(QUEUE_OBJ) | $(BIN_DIR)
	$(CC) -o $@ $^ $(CFLAGS)

$(BIN_DIR)/backoffice_user: $(BUILD_DIR)/backoffice_user.o $(QUEUE_OBJ) | $(BIN_DIR)
	$(CC) -o $@ $^ $(CFLAGS)

$(BUILD_DIR) $(BIN_DIR):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR) log.txt

.PHONY: all
