<script lang="ts">
  import { page } from '$app/stores';
  import BridgeTabs from '$components/Bridge/BridgeTabs.svelte';
  import { ConnectButton } from '$components/ConnectButton';
  import { Icon } from '$components/Icon';
  import { LogoWithText } from '$components/Logo';
  import { drawerToggleId } from '$components/SideNavigation';
  import { account } from '$stores/account';

  $: isBridgePage = $page.route.id === '/' || $page.route.id === '/nft';
</script>

<header
  class="
    sticky-top
    f-between-center
    justify-between
    z-10
    px-4
    py-[20px]
    border-b
    border-b-divider-border
    glassy-background
    bg-grey-5/10
    dark:bg-grey-900/10
    md:border-b-0
    md:px-10
    md:py-7
 ">
  <LogoWithText width={77} height={21} class="md:hidden" textFillClass={'fill-primary-content'} />

  <div class="flex justify-end w-full">
    {#if isBridgePage}
      <BridgeTabs class="hidden md:flex md:flex-1" />
    {/if}

    <ConnectButton connected={$account?.isConnected} />
  </div>

  <label for={drawerToggleId} class="ml-[10px] md:hidden">
    <Icon type="bars-menu" />
  </label>
</header>
