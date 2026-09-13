defmodule LiveWeb.Live.CounterLive do
  use LiveWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.vue count={@count} v-component="Counter" />
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", %{"diff" => value}, socket) do
    amount = String.to_integer(value)
    {:noreply, update(socket, :count, &(&1 + amount))}
  end
end
