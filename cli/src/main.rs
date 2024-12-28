use tokio;
use clap::{self, Parser, Subcommand};
use postgrest::Postgrest;
use dotenv::dotenv;
use std::env::var;
use go_true::{EmailOrPhone, Api as GoTrueApi};

#[derive(Parser, Debug)] // requires `derive` feature
#[command(name = "crm")]
#[command(bin_name = "crm")]
#[command(styles = CLAP_STYLING)]
struct Cli {
    #[command(subcommand)]
    commands: Commands,

    #[arg(short, long)]
    email: String,

    #[arg(short, long)]
    password: String,
}

// See also `clap_cargo::style::CLAP_STYLING`
pub const CLAP_STYLING: clap::builder::styling::Styles = clap::builder::styling::Styles::styled()
    .header(clap_cargo::style::HEADER)
    .usage(clap_cargo::style::USAGE)
    .literal(clap_cargo::style::LITERAL)
    .placeholder(clap_cargo::style::PLACEHOLDER)
    .error(clap_cargo::style::ERROR)
    .valid(clap_cargo::style::VALID)
    .invalid(clap_cargo::style::INVALID);

#[derive(Subcommand, Debug)]
#[command(version, about, long_about = None)]
enum Commands {
    Add {
        #[command(subcommand)]
        commands: AddSucommands,
    }
}

#[derive(Subcommand, Debug)]
#[command(version, about, long_about = None)]
enum AddSucommands {
    FromUpworkProposal {
        proposal_link: String,
    } 
}

#[tokio::main]
async fn main() {
    dotenv().ok(); 
    let args = Cli::parse();

    println!("{:?}", args);

    match args.commands {
        Commands::Add { commands } => {
            match commands {
                AddSucommands::FromUpworkProposal { proposal_link } => {
                    let anon_key = var("SUPABASE_ANON_KEY").expect("set the service role key");
                    let domain = var("SUPABASE_URL").expect("set the rest api domain");
                    let go_true_api = GoTrueApi::new(format!("{}/auth/v1", domain))
                        .insert_header("apikey", anon_key);

                    let session = go_true_api
                        .sign_in(EmailOrPhone::Email(args.email), &args.password)
                        .await.expect("Couldn't create GoTrue session");

                    let result = client(session.access_token)
                        .rpc("add_contact_from_upwork_proposal", format!("{{ \"proposal_link\": \"{}\"}}", proposal_link))
                        .execute()
                        .await;

                    match result {
                        Err(error) => {
                            println!("Error: {:?}", error);
                        },
                        Ok(data) => {
                            println!("success: {:?}", data.text().await);
                        }
                    }
                }
            }

        }
    }
}


fn client(access_token: String) -> Postgrest {
    dotenv().ok(); 
    let domain = var("SUPABASE_URL").expect("set the rest api domain");
    let anon_key = var("SUPABASE_ANON_KEY").expect("set the service role key");

    Postgrest::new(format!("{}/rest/v1", domain))
        .insert_header("apikey", anon_key)
        .insert_header("Authorization", format!("Bearer {}", access_token))

}

