defmodule JswatchWeb.ClockManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    # get time
    {_, now} = :calendar.local_time()
    time = Time.from_erl!(now)

    # create time value for when alarm should sound
    alarm = Time.add(time, 10)

    # send out to woring_working
    Process.send_after(self(), :working_working, 1000)

    # return state
    {:ok, %{ui_pid: ui, time: time, alarm: alarm, st: Working}}
  end

  def handle_info(:update_alarm, state) do
    {_, now} = :calendar.local_time()
    time = Time.from_erl!(now)
    alarm = Time.add(time, 5)

    # legit sends a process out to add five seconds to the alarm
    {:noreply, %{state | alarm: alarm}}
  end

  def handle_info(:working_working, %{ui_pid: ui, time: time, alarm: alarm, st: Working} = state) do
    Process.send_after(self(), :working_working, 1000)
    time = Time.add(time, 1)
    if time == alarm do
      IO.puts("ALARM!!!")
      :gproc.send({:p, :l, :ui_event}, :start_alarm)
    end
    GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string })
    {:noreply, state |> Map.put(:time, time) }
  end

  def handle_info(_event, state), do: {:noreply, state}
end
