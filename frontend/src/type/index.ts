export type Pet = {
    id: string,
    name: string,
    owner: string,
    hp: number,
    level: number,
}

export type State = {
    users: User[]
}

export type User = {
    owner: string,
    pet: string,
}
