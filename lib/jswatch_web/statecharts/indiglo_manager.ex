defmodule JswatchWeb.IndigloManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})

    # start with indiglo off, timer: nil, because no timer yet started
    {:ok, %{ui_pid: ui, st: IndigloOff, count: 0, timer1: nil}}
  end

  # flag: add a handle_info for when IndigloOn

  # PRESSED TOP-RIGHT
  def handle_info(:"top-right-pressed", %{ui_pid: pid, st: IndigloOff} = state) do

    # cast to front
    GenServer.cast(pid, :set_indiglo)

    # set state to indiglo on
    {:noreply, %{state | st: IndigloOn}}
  end

  # RELEASED TOP-RIGHT
  def handle_info(:"top-right-released", %{st: IndigloOn} = state) do

    # will take 2 seconds to turn indiglo off
    timer = Process.send_after(self(), Waiting_IndigloOff, 2000)

    # weird asfuck, but adds a porcess to state, that will activate indigloOff
    {:noreply, %{state | st: Waiting, timer1: timer}}
  end

  # NO TIMER
  def handle_info(Waiting_IndigloOff, %{ui_pid: pid, st: Waiting} = state) do
    IO.inspect("hello")
    # turns indiglo off on front end
    GenServer.cast(pid, :unset_indiglo)

    # return to IndigloOff
    {:noreply, %{state| st: IndigloOff}}
  end

  # Pienso que es discrepancia porque requiere de un timer que siempre se acabara al llamar la funcion
  def handle_info(Waiting_IndigloOff, %{ui_pid: pid, st: Waiting, timer1: timer} = state) do
    IO.inspect("hi mom")
    if timer != nil do
      Process.cancel_timer(timer)
    end
    GenServer.cast(pid, :unset_indiglo)
    Process.send_after(self(), AlarmOff_AlarmOn, 500)

    {:noreply, %{state| count: 51, timer1: nil, st: AlarmOff}}
  end

  def handle_info(:start_alarm, %{ui_pid: pid, st: IndigloOff} = state) do
    Process.send_after(self(), AlarmOn_AlarmOff, 500)
    GenServer.cast(pid, :set_indiglo)
    {:noreply, %{state | count: 51, st: AlarmOn}}
  end

  def handle_info(:start_alarm, %{st: IndigloOn} = state) do
    Process.send_after(self(), AlarmOff_AlarmOn, 500)
    {:noreply, %{state | count: 51, st: AlarmOff}}
  end

  # when using indiglo, top left still works with alarm
  def handle_info(:"top-left-pressed", state) do
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, state}
  end


  def handle_info(AlarmOn_AlarmOff, %{ui_pid: pid, count: count, st: AlarmOn} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOff_AlarmOn, 500)
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOff}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end

  end
  def handle_info(AlarmOff_AlarmOn, %{ui_pid: pid, count: count, st: AlarmOff} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOn_AlarmOff, 500)
      GenServer.cast(pid, :set_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOn}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end
  end

  def handle_info(event, state) do
    IO.inspect(event)
    {:noreply, state}
  end
end
