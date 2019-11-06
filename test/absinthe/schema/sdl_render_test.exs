defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule SdlTestSchema do
    use Absinthe.Schema

    @sdl """
    schema {
      query: Query
    }

    directive @foo(name: String!) on OBJECT | SCALAR

    interface Animal {
      legCount: Int!
    }

    \"""
    A submitted post
    Multiline description
    \"""
    type Post {
      old: String @deprecated(reason: \"""
        It's old
        Really old
      \""")

      sweet: SweetScalar

      "Something"
      title: String!
    }

    input ComplexInput {
      foo: String
    }

    scalar SweetScalar

    type Query {
      echo(
        category: Category!

        "The number of times"
        times: Int = 10
      ): [Category!]!
      posts: Post
      search(limit: Int, sort: SorterInput!): [SearchResult]
      defaultBooleanArg(boolean: Boolean = false): String
      defaultInputArg(input: ComplexInput = {foo: "bar"}): String
      defaultListArg(things: [String] = ["ThisThing"]): [String]
      defaultEnumArg(category: Category = NEWS): Category
    }

    type Dog implements Pet & Animal {
      legCount: Int!
      name: String!
    }

    "Simple description"
    enum Category {
      "Just the facts"
      NEWS

      \"""
      What some rando thinks

      Take with a grain of salt
      \"""
      OPINION

      CLASSIFIED
    }

    interface Pet {
      name: String!
    }

    "One or the other"
    union SearchResult = Post | User

    "Sort this thing"
    input SorterInput {
      "By this field"
      field: String!
    }

    type User {
      name: String!
    }
    """
    import_sdl @sdl
    def sdl, do: @sdl

    def hydrate(%{identifier: :animal}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(%{identifier: :pet}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []
  end

  test "Render SDL from blueprint defined with SDL" do
    assert Absinthe.Schema.to_sdl(SdlTestSchema) == SdlTestSchema.sdl()
  end

  describe "Render SDL" do
    test "for a type" do
      assert_rendered("""
      type Person implements Entity {
        name: String!
        baz: Int
      }
      """)
    end

    test "for an interface" do
      assert_rendered("""
      interface Entity {
        name: String!
      }
      """)
    end

    test "for an input" do
      assert_rendered("""
      "Description for Profile"
      input Profile {
        "Description for name"
        name: String!
      }
      """)
    end

    test "for a union" do
      assert_rendered("""
      union Foo = Bar | Baz
      """)
    end

    test "for a scalar" do
      assert_rendered("""
      scalar MyGreatScalar
      """)
    end

    test "for a directive" do
      assert_rendered("""
      directive @foo(name: String!) on OBJECT | SCALAR
      """)
    end

    test "for a schema declaration" do
      assert_rendered("""
      schema {
        query: Query
      }
      """)
    end
  end

  defp assert_rendered(sdl) do
    rendered_sdl =
      with {:ok, %{input: doc}} <- Absinthe.Phase.Parse.run(sdl),
           %Absinthe.Language.Document{definitions: [node]} <- doc,
           blueprint = Absinthe.Blueprint.Draft.convert(node, doc) do
        Inspect.inspect(blueprint, %Inspect.Opts{pretty: true})
      end

    assert sdl == rendered_sdl
  end

  defmodule MacroTestSchema do
    use Absinthe.Schema

    query do
      field :echo, :string do
        arg :times, :integer, default_value: 10, description: "The number of times"
      end
    end

    object :order do
      field :id, :id
      field :name, :string
    end

    object :category do
      field :name, :string
    end

    union :search_result do
      types [:order, :category]
    end
  end

  test "Render SDL from blueprint defined with macros" do
    assert Absinthe.Schema.to_sdl(MacroTestSchema) ==
             """
             schema {
               query: RootQueryType
             }

             type RootQueryType {
               echo(
                 "The number of times"
                 times: Int
               ): String
             }

             type Category {
               name: String
             }

             union SearchResult = Order | Category

             type Order {
               id: ID
               name: String
             }
             """
  end
end
