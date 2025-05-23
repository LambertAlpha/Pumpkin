import { useCurrentAccount, useSuiClient } from "@mysten/dapp-kit";
import { Container } from "@radix-ui/themes";
import { PetComponent } from "../components/ui/PetComponent";
import { AdoptPetComponent } from "../components/ui/AdoptPet";
import { queryState } from "@/lib/contracts";
import { useState, useEffect } from "react";
import { Pet } from "../type";
import type { State } from "../type";
import { useQuery } from "@tanstack/react-query";

function Main() {
    const account = useCurrentAccount();
    const [userPet, setUserPet] = useState<Pet | null>(null);
    const suiClient = useSuiClient();

    const { data: stateData } = useQuery({
        queryKey: ['user-pet', account?.address],
        queryFn: () => queryState(suiClient),
        enabled: !!account,
    });

    useEffect(() => {
        const state = stateData as State | undefined;
        if (account && state && Array.isArray(state.users)) {
            const currentUser = state.users.find(
                (user: any) => user.owner === account.address
            );
            if (currentUser && typeof currentUser.pet === 'object') {
                setUserPet(currentUser.pet as Pet);
            } else {
                setUserPet(null);
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