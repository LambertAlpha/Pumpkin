import { ConnectButton } from "@mysten/dapp-kit";
import { Box, Flex, Heading } from "@radix-ui/themes";
import { Link } from "react-router-dom";

export default function NaviBar() {
  return (
    <Flex
      position="sticky"
      px="4"
      py="2"
      justify="between"
      style={{
        borderBottom: "1px solid var(--gray-a2)",
      }}
    >
      <Box className="flex items-center gap-4">
        <Heading>寵物番茄鐘</Heading>
        <nav className="flex gap-4">
          <Link to="/" className="text-foreground hover:text-primary">
            首頁
          </Link>
          <Link to="/user" className="text-foreground hover:text-primary">
            我的寵物
          </Link>
        </nav>
      </Box>

      <Box className="flex items-center gap-2">
        <ConnectButton />
      </Box>
    </Flex>
  );
} 