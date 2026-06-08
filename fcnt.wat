(module

  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (import "wasi_snapshot_preview1" "fd_prestat_get"
    (func $fd_prestat_get (param i32 i32) (result i32)))

  (global $STDIN i32 (i32.const 0))
  (global $STDOUT i32 (i32.const 1))
  (global $STDERR i32 (i32.const 2))

  (global $ESUCCESS i32 (i32.const 0))
  (global $EBADF i32 (i32.const 8))

  (global $FD_START i32 (i32.const 3))

  (global $FD_WRIT_IOVEC_PTR i32 (i32.const 0x0001_0000))
  (global $FD_WRIT_IOBUF_PTR i32 (i32.const 0x0002_0000))
  (global $FD_WRIT_BWRIT_PTR i32 (i32.const 0x0003_0000))

  (global $FD_PRESTAT_GET_BUF i32 (i32.const 0x0004_0000))

  (memory (export "memory") 5)

  (func $count_fds_r
    (param $fd i32)
    (param $ptr i32)
    (param $cnt i32)

    (result i32)

    (local $ret i32)

    local.get $fd
    local.get $ptr
    call $fd_prestat_get
    local.tee $ret
    global.get $EBADF
    i32.eq
    if
      local.get $cnt
      return
    end

    local.get $ret
    i32.const 0
    i32.ne
    if
      i32.const -1
      return
    end

    local.get $fd
    i32.const 1
    i32.add

    local.get $ptr

    local.get $cnt
    i32.const 1
    i32.add

    return_call $count_fds_r
  )

  (func $count_fds_default
    (result i32)
    global.get $FD_START
    global.get $FD_PRESTAT_GET_BUF
    i32.const 0
    call $count_fds_r
  )

  (func $i32le2stdout
    (param $i i32)

    (result i64)

    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 4 ;; 32-bit integer = 4 bytes
    i32.store offset=4

    ;; copy the val
    global.get $FD_WRIT_IOBUF_PTR
    local.get $i
    i32.store

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 4
    i32.ne
    if
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $main (export "_start")
    call $count_fds_default
    call $i32le2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end

    i32.const 0
    call $proc_exit
  )

)
