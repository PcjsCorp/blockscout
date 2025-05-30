defmodule BlockScoutWeb.API.V2.WithdrawalController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [paging_options: 1, next_page_params: 3, split_list_by_page: 1]

  import BlockScoutWeb.PagingHelper, only: [delete_parameters_from_next_page_params: 1]
  import Explorer.MicroserviceInterfaces.BENS, only: [maybe_preload_ens: 1]
  import Explorer.MicroserviceInterfaces.Metadata, only: [maybe_preload_metadata: 1]

  alias Explorer.Chain

  def withdrawals_list(conn, params) do
    full_options =
      [
        necessity_by_association: %{
          [address: [:names, :smart_contract, proxy_implementations_association()]] => :optional,
          block: :optional
        },
        api?: true
      ]
      |> Keyword.merge(paging_options(params))

    withdrawals_plus_one = Chain.list_withdrawals(full_options)
    {withdrawals, next_page} = split_list_by_page(withdrawals_plus_one)

    next_page_params = next_page |> next_page_params(withdrawals, delete_parameters_from_next_page_params(params))

    conn
    |> put_status(200)
    |> render(:withdrawals, %{
      withdrawals: withdrawals |> maybe_preload_ens() |> maybe_preload_metadata(),
      next_page_params: next_page_params
    })
  end

  def withdrawals_counters(conn, _params) do
    conn
    |> json(%{
      withdrawals_count: Chain.count_withdrawals_from_cache(api?: true),
      withdrawals_sum: Chain.sum_withdrawals_from_cache(api?: true),
      # todo: Both properties below should be removed in favour `withdrawals_count` and `withdrawals_sum` properties with the next release after 8.0.0
      withdrawal_count: Chain.count_withdrawals_from_cache(api?: true),
      withdrawal_sum: Chain.sum_withdrawals_from_cache(api?: true)
    })
  end
end
