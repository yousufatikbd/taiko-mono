<script lang="ts">
  import Connect from "../../components/buttons/Connect.svelte";
  import { _ } from "svelte-i18n";
  import { balance } from "../../store/balance";
  import { utils } from "ethers";
  import Withdraw from "../../components/buttons/Withdraw.svelte";
</script>

<div class="container mx-auto  max-w-fit text-center my-10">
  <div class="rounded-3xl border-2 border-bridge-form border-solid p-2 md:p-6">
    Dashboard
    {#if $balance}
      <div class="text-2xl font-bold">
        Balance: {utils.formatEther($balance)}
        {import.meta.env.VITE_TOKEN_SYMBOL ?? "TKO"}
      </div>

      <Withdraw />
    {:else}
      <Connect />
    {/if}
  </div>
</div>
