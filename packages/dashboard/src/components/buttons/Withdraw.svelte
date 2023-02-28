<script lang="ts">
  import { _ } from "svelte-i18n";
  import withdrawBalance from "../../utils/withdrawBalance";
  import { signer } from "../../store/signer";
  import { errorToast, successToast } from "../../utils/toast";
  import Loader from "../Loader.svelte";

  let loading: boolean = false;
  async function withdraw() {
    if (loading) return;
    loading = true;
    try {
      // todo: show tx hash, link to explorer
      const tx = await withdrawBalance(
        $signer,
        import.meta.env.VITE_TAIKO_L1_ADDRESS
      );
      successToast("Transaction submitted");
    } catch (e) {
      errorToast("Error submitting transaction");
    } finally {
      loading = false;
    }
  }
</script>

<button class="btn btn-md" on:click={async () => await withdraw()}
  >{#if loading}
    <Loader />
  {:else}
    Withdraw
  {/if}
</button>
