defmodule DoorLock.LockTest do
  use ExUnit.Case

  alias DoorLock.Lock
  alias DoorLock.Store

  setup do
    # Ensure clean ETS table before each test
    Store.put_pressed_buttons([])

    code = [1, 2, 3, 4]
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

  test "only keeps last 4 pressed buttons", %{lock_pid: lock_pid} do
    # Last 4 digits are incorrect
    for code <- [5, 4, 3, 2, 1, 5, 6, 7, 8] do
      assert :ok = Lock.press_button(lock_pid, code)
    end

    assert Lock.pressed_buttons(lock_pid) == [5, 6, 7, 8]
    assert Lock.is_locked(lock_pid)

    # Last 4 digits are correct
    for code <- [5, 4, 3, 2, 1, 2, 3, 4] do
      assert :ok = Lock.press_button(lock_pid, code)
    end

    refute Lock.is_locked(lock_pid)
    assert Lock.pressed_buttons(lock_pid) == [1, 2, 3, 4]
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
