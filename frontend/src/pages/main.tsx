import { useCurrentAccount, useSuiClientQuery, useSuiClient } from "@mysten/dapp-kit";
import { Container } from "@radix-ui/themes";
import { PetComponent } from "../components/ui/PetComponent";
import { AdoptPetComponent } from "../components/ui/AdoptPet";
import { queryState } from "@/lib/contracts";
import { useState, useEffect } from "react";
import { Pet } from "../type";
import type { State } from "../type";

function Main() {
    const account = useCurrentAccount();
    const [userPet, setUserPet] = useState<Pet | null>(null);
    const suiClient = useSuiClient();

    const { data: stateData } = useSuiClientQuery<State>(
        ['user-pet', account?.address],
        () => queryState(suiClient),
        {
            enabled: !!account,
        }
    );

    useEffect(() => {
        if (account && stateData && Array.isArray(stateData.users)) {
            const currentUserPet = stateData.users.find(
                (user) => user.owner === account.address
            )?.pet;
            if (currentUserPet) {
                setUserPet(currentUserPet);
            }
        }
    }, [account, stateData]);

    return (
        <Container>
            <Container
                mt="5"
                pt="2"
                px="4"
                style={{ 
                    background: "var(--gray-a2)", 
                    minHeight: 500,
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center"
                }}
            >
                <div style={{ display: "flex", justifyContent: "center", width: "100%" }}>
                    {!userPet ? (
                        <AdoptPetComponent />
                    ) : (
                        <PetComponent pet={userPet} />
                    )}
                </div>
            </Container>
        </Container>
    );
}

export default Main;