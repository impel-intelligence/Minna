import ProjectDescription

let tuist = Tuist(
    fullHandle: "Impel-Intelligence/Iris",
    project: .tuist(
        generationOptions: .options(enableCaching: true)
    )
)
