defmodule DoorLock.LockTest do
  use ExUnit.Case

  alias DoorLock.Lock

  setup do
    code = [1, 2, 3]
    lock_again_timeout = 1_000
    opts = [code: code, lock_again_timeout: lock_again_timeout, is_registered: false]
    lock_pid = start_supervised!({Lock, opts})

    %{lock_pid: lock_pid, code: code, lock_again_timeout: lock_again_timeout}
  end

  test "is a process", %{lock_pid: lock_pid} do
    assert is_pid(lock_pid)
  end

  test "starts as locked", %{lock_pid: lock_pid} do
    assert Lock.is_locked(lock_pid)
  end

  test "unlocks when correct code is pressed", %{lock_pid: lock_pid, code: code} do
    assert Lock.is_locked(lock_pid)

    for code <- code do
      assert :ok = Lock.press_button(lock_pid, code)
    end

    refute Lock.is_locked(lock_pid)
  end

  test "stays locked when incorrect code is pressed", %{lock_pid: lock_pid, code: code} do
    assert Lock.is_locked(lock_pid)

    for code <- code do
      assert :ok = Lock.press_button(lock_pid, code + 1)
    end

    assert Lock.is_locked(lock_pid)
  end

  test "locks again after timeout", %{
    lock_pid: lock_pid,
    code: code,
    lock_again_timeout: lock_again_timeout
  } do
    assert Lock.is_locked(lock_pid)

    for code <- code do
      assert :ok = Lock.press_button(lock_pid, code)
    end

    refute Lock.is_locked(lock_pid)

    Process.sleep(lock_again_timeout + 100)
    assert Lock.is_locked(lock_pid)
  end
end
